import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'entry_details_screen.dart';

class ViewEntriesScreen extends StatefulWidget {
  final DateTime date;

  const ViewEntriesScreen({super.key, required this.date});

  @override
  _ViewEntriesScreenState createState() => _ViewEntriesScreenState();
}

class _ViewEntriesScreenState extends State<ViewEntriesScreen> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _fetchEntries();
  }

  Future<List<Map<String, dynamic>>> _fetchEntries() async {
    final dbHelper = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      final selectedDate = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      return await dbHelper.getEntriesByDate(userId, selectedDate);
    }
    return [];
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'great': return const Color(0xFF388E3C);
      case 'good': return const Color(0xFF93C765);
      case 'meh': return const Color(0xFFA5D6A7);
      case 'bad': return const Color(0xFFE57580);
      case 'awful': return const Color(0xFFD05151);
      default: return const Color(0xFF2C2C2C);
    }
  }

  IconData _getActivityIcon(String? activity) {
    switch (activity) {
      case 'Work': return Icons.work;
      case 'Exercise': return Icons.fitness_center;
      case 'Read': return Icons.menu_book;
      case 'Gaming': return Icons.videogame_asset;
      case 'Movie': return Icons.movie;
      case 'Shopping': return Icons.shopping_cart;
      case 'Health': return Icons.local_hospital;
      case 'Music': return Icons.music_note;
      case 'Relax': return Icons.spa;
      case 'Travel': return Icons.airplanemode_active;
      case 'Food': return Icons.restaurant;
      case 'Socialize': return Icons.people;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3CB371),
        title: Text(
          '${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}',
          style: const TextStyle(fontSize: 24, color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C), size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading entries.'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No entries for this date.'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final entryId = entry['id'];
                final moodColor = _getMoodColor(entry['mood']);
                final date = entry['date'];
                final time = entry['time'];
                final activity = entry['activity'];
                final note = entry['note'];
                final imagePath = entry['image_path'];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  decoration: BoxDecoration(
                    color: moodColor,
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
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
