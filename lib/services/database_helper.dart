import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moodtracker.db');

    return await openDatabase(
      path,
      version: 1, 
      onCreate: _onCreate,
    );
  }

  Future<String> getMostFrequentMoodForLatestMonth(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final result = await db.rawQuery('''
      SELECT mood, COUNT(mood) as mood_count
      FROM entries
      WHERE user_id = ? AND date >= ?
      GROUP BY mood
      ORDER BY mood_count DESC
      LIMIT 1
    ''', [userId, firstDayOfMonth.toIso8601String()]);

    if (result.isNotEmpty) {
      return result.first['mood'] as String;
    } else {
      return 'No data'; 
    }
  }

  Future<List<String>> getTopActivitiesForAllTime(int userId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT activity, COUNT(activity) as activity_count
      FROM entries
      WHERE user_id = ?
      GROUP BY activity
      ORDER BY activity_count DESC
      LIMIT 3
    ''', [userId]);

    if (result.isNotEmpty) {
      return result.map((row) => row['activity'] as String).toList();
    } else {
      return []; 
    }
  }


  Future<Map<String, String>> getMoodActivityPairsForAllTime(int userId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT mood, activity, COUNT(*) as pair_count
      FROM entries
      WHERE user_id = ?
      GROUP BY mood, activity
      ORDER BY pair_count DESC
      LIMIT 1
    ''', [userId]);

    if (result.isNotEmpty) {
      return {
        'mood': result.first['mood'] as String,
        'activity': result.first['activity'] as String,
      };
    } else {
      return {'mood': 'No data', 'activity': 'No data'};
    }
  }


  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        mood TEXT NOT NULL,
        activity TEXT,
        note TEXT,
        image_path TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        is_public INTEGER DEFAULT 0,   -- Track public posts
        is_anonymous INTEGER DEFAULT 0, -- Track anonymous status
        reactions TEXT,                -- Store reactions
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }


  // ----------

  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getEntryById(int entryId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateEntry(int entryId, Map<String, dynamic> updatedEntry) async {
    Database db = await database;
    return await db.update(
      'entries',
      updatedEntry,
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updatePassword(int userId, String newPassword) async {
    Database db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUsername(int id, String newUsername) async {
    Database db = await database;
    return await db.update(
      'users',
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------- 

  Future<int> insertEntry(Map<String, dynamic> entry) async {
    Database db = await database;
    return await db.insert('entries', entry);
  }

  Future<List<Map<String, dynamic>>> getEntriesByUserId(int userId) async {
    Database db = await database;
    return await db.query(
      'entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getEntriesByDate(int userId, String date) async {
    Database db = await database;
    return await db.query(
      'entries',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      orderBy: 'time DESC',
    );
  }

  // ----------

  Future<Map<String, int>> countEntriesByMood(int userId) async {
    Database db = await database;
    List<String> moods = ['great', 'good', 'meh', 'bad', 'awful'];
    Map<String, int> moodCounts = {};
    for (String mood in moods) {
      final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM entries WHERE user_id = ? AND mood = ?',
        [userId, mood],
      ));
      moodCounts[mood] = count ?? 0;
    }
    return moodCounts;
  }

  Future<Map<String, int>> countEntriesByActivity(int userId) async {
    final db = await database;
    final result = await db.query(
      'entries',
      columns: ['activity', 'COUNT(activity) as count'],
      where: 'user_id = ?',
      whereArgs: [userId],
      groupBy: 'activity',
    );

    final Map<String, int> activityCounts = {};
    for (var row in result) {
      final activity = row['activity'] as String?;
      final count = row['count'] as int? ?? 0;

      if (activity != null) {
        activityCounts[activity] = count;
      }
    }
    return activityCounts;
  }

  Future<String> getAverageMood(int userId) async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT mood, COUNT(mood) as count FROM entries WHERE user_id = ? GROUP BY mood ORDER BY count DESC LIMIT 1',
      [userId]
    );
    return result.isNotEmpty ? result.first['mood'] as String : 'No data';
  }

  Future<double> getPositiveEventPercentage(int userId) async {
    Database db = await database;
    final positiveCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM entries WHERE user_id = ? AND (mood = 'great' OR mood = 'good' OR mood = 'meh')", [userId])
    ) ?? 0;
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM entries WHERE user_id = ?", [userId])
    ) ?? 1;

    return (positiveCount / totalCount) * 100;
  }

  Future<List<Map<String, dynamic>>> getLatestMoodPerDay(int userId, int month, int year) async {
    Database db = await database;

    return await db.rawQuery('''
      SELECT date, mood FROM entries
      WHERE user_id = ? 
        AND strftime('%m', date) = ? 
        AND strftime('%Y', date) = ?
      GROUP BY date
      ORDER BY date DESC
    ''', [userId, month.toString().padLeft(2, '0'), year.toString()]);
  }

  Future<int> deleteEntry(int entryId) async {
    Database db = await database;
    return await db.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }


  // ----------

  Future<void> close() async {
    Database db = await database;
    db.close();
  }

  // ----------

  Future<int> updateEntryVisibility(int entryId, bool isPublic) async {
    Database db = await database;
    return await db.update(
      'entries',
      {'is_public': isPublic ? 1 : 0},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<List<Map<String, dynamic>>> getPublicEntries({String? mood, String? activity}) async {
    final db = await database;
    
    String sql = '''
      SELECT entries.id, entries.mood, entries.activity, entries.note, 
            entries.image_path, entries.date, entries.time, entries.is_public, 
            entries.is_anonymous, entries.user_id, users.username
      FROM entries 
      LEFT JOIN users ON entries.user_id = users.id 
      WHERE entries.is_public = 1
    ''';
    
    List<dynamic> whereArgs = [];

    if (mood != null) {
      sql += ' AND entries.mood = ?';
      whereArgs.add(mood);
    }

    if (activity != null) {
      sql += ' AND entries.activity = ?';
      whereArgs.add(activity);
    }

    sql += ' ORDER BY entries.date DESC, entries.time DESC';

    return await db.rawQuery(sql, whereArgs);
  }



  Future<int> getReactionsCount(int entryId) async {
    return 0; 
  }

  Future<Map<String, dynamic>?> getPublicEntryById(int entryId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'entries',
      where: 'id = ? AND is_public = 1',
      whereArgs: [entryId],
    );
    return results.isNotEmpty ? results.first : null;
  }


  Future<void> addReactionToEntry(int entryId, String reactionType) async {

    print("Reaction '$reactionType' added to entry ID $entryId");
  }


  Future<void> updateReactions(int entryId, Map<String, int> reactions) async {
    final db = await database;


    final reactionsJson = jsonEncode(reactions);

    await db.update(
      'entries',
      {'reactions': reactionsJson},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }


  Future<Map<String, int>> getReactions(int entryId) async {
    final db = await database;

    final result = await db.query(
      'entries',
      columns: ['reactions'],
      where: 'id = ?',
      whereArgs: [entryId],
    );

    if (result.isNotEmpty) {
      final reactionsJson = result.first['reactions'] as String?;
      if (reactionsJson != null && reactionsJson.isNotEmpty) {
        return Map<String, int>.from(jsonDecode(reactionsJson));
      }
    }
   
    return {'❤️': 0, '😊': 0, '😢': 0, '😮': 0};
  }

  Future<List<Map<String, dynamic>>> getEntriesWithFilter(int? userId, String? mood, String? activity) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (mood != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'mood = ?';
      whereArgs.add(mood);
    }

    if (activity != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'activity = ?';
      whereArgs.add(activity);
    }

    return await db.query(
      'entries',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, time DESC',
    );
  }
}
