import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mood_selection_screen.dart';
import 'settings_screen.dart';
import 'entry_details_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import '../services/database_helper.dart';
import 'public_feed_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;
  final GlobalKey<_HomeContentState> _homeContentKey = GlobalKey<_HomeContentState>();

  static List<Widget> _pages = <Widget>[
    const SettingsScreen(),
    const CalendarScreen(),
    HomeContent(),
    const PublicFeedScreen(),
    const StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      const SettingsScreen(),
      const CalendarScreen(),
      HomeContent(key: _homeContentKey), 
      const PublicFeedScreen(),
      const StatsScreen(),
    ];
  }

  void _onIconTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedMood;
        String? selectedActivity;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Search Entries"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: const Text("Select Mood"),
                    value: selectedMood,
                    isExpanded: true,
                    items: ['great', 'good', 'meh', 'bad', 'awful']
                        .map((mood) => DropdownMenuItem(
                              value: mood,
                              child: Text(mood),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMood = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    hint: const Text("Select Activity"),
                    value: selectedActivity,
                    isExpanded: true,
                    items: [
                      'Work', 'Exercise', 'Read', 'Gaming', 'Movie', 'Shopping', 'Health', 'Music', 'Relax', 'Travel', 'Food', 'Socialize'
                    ].map((activity) => DropdownMenuItem(
                          value: activity,
                          child: Text(activity),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedActivity = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Clear"),
                  onPressed: () {
                    setState(() {
                      selectedMood = null;
                      selectedActivity = null;
                    });
                    Navigator.of(context).pop();
                    _homeContentKey.currentState?._applyFilters(null, null);
                  },
                ),
                TextButton(
                  child: const Text("Search"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _homeContentKey.currentState?._applyFilters(selectedMood, selectedActivity);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? AppBar(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'DailyMood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF3CB371), size: 30),
                onPressed: () {
                  _showFilterDialog();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF3CB371), size: 36),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MoodSelectionScreen(selectedDate: DateTime.now()),
                      ),
                    ).then((_) => setState(() {})); 
                  },
                ),
              ],
            )

          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF3CB371),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.settings, size: 36),
              color: _selectedIndex == 0 ? Colors.white : const Color(0xFF343330),
              onPressed: () => _onIconTapped(0),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today, size: 36),
              color: _selectedIndex == 1 ? Colors.white : const Color(0xFF343330),
              onPressed: () => _onIconTapped(1),
            ),
            IconButton(
              icon: const Icon(Icons.home, size: 36),
              color: _selectedIndex == 2 ? Colors.white : const Color(0xFF343330),
              onPressed: () => _onIconTapped(2),
            ),
            IconButton(
              icon: const Icon(Icons.public, size: 36),
              color: _selectedIndex == 3 ? Colors.white : const Color(0xFF343330),
              onPressed: () => _onIconTapped(3),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 36),
              color: _selectedIndex == 4 ? Colors.white : const Color(0xFF343330),
              onPressed: () => _onIconTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;
  String? filterMood;
  String? filterActivity;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _fetchEntries();
  }

  // ฟังก์ชันสำหรับการกรองข้อมูลตามอารมณ์และกิจกรรม
  void _applyFilters(String? mood, String? activity) {
    setState(() {
      filterMood = mood;
      filterActivity = activity;

      final prefs = SharedPreferences.getInstance();
      _entriesFuture = prefs.then((prefs) {
        final userId = prefs.getInt('userId');
        if (userId != null) {
          final dbHelper = DatabaseHelper();
          return dbHelper.getEntriesWithFilter(userId, mood, activity);
        }
        return [];
      });
    });
  }

  Future<List<Map<String, dynamic>>> _fetchEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      final dbHelper = DatabaseHelper();
      return await dbHelper.getEntriesByUserId(userId);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading entries.'));
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return const Center(child: Text('No entries found.'));
        } else {
          final entries = snapshot.data!;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final entryId = entry['id'];
              final mood = entry['mood'];
              final activity = entry['activity'];
              final note = entry['note'];
              final imagePath = entry['image_path'];
              final date = entry['date'];
              final time = entry['time'];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getMoodColor(mood),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(
                    '$date - $time',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activity != null)
                        Icon(
                          _getActivityIcon(activity),
                          color: Colors.white,
                          size: 30,
                        )
                      else
                        const SizedBox(width: 30),
                      const SizedBox(width: 8),
                      if (note != null && note.isNotEmpty)
                        const Icon(
                          Icons.textsms,
                          color: Colors.white,
                          size: 30,
                        )
                      else
                        const SizedBox(width: 30),
                      const SizedBox(width: 8),
                      if (imagePath != null && imagePath.isNotEmpty)
                        const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 30,
                        )
                      else
                        const SizedBox(width: 30),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EntryDetailsScreen(entryId: entryId),
                      ),
                    ).then((_) => setState(() {
                          _entriesFuture = _fetchEntries();
                        }));
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  // ฟังก์ชันกำหนดสีตามอารมณ์
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'great':
        return const Color(0xFF388E3C);
      case 'good':
        return const Color(0xFF93C765);
      case 'meh':
        return const Color(0xFFA5D6A7);
      case 'bad':
        return const Color(0xFFE57580);
      case 'awful':
        return const Color(0xFFD05151);
      default:
        return const Color(0xFF2C2C2C);
    }
  }

  IconData _getActivityIcon(String? activity) {
    switch (activity) {
      case 'Work':
        return Icons.work;
      case 'Exercise':
        return Icons.fitness_center;
      case 'Read':
        return Icons.menu_book;
      case 'Gaming':
        return Icons.videogame_asset;
      case 'Movie':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Health':
        return Icons.local_hospital;
      case 'Music':
        return Icons.music_note;
      case 'Relax':
        return Icons.spa;
      case 'Travel':
        return Icons.airplanemode_active;
      case 'Food':
        return Icons.restaurant;
      case 'Socialize':
        return Icons.people;
      default:
        return Icons.help_outline;
    }
  }
}
