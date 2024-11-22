import 'package:flutter/material.dart';
import 'mood_activity_screen.dart';
import '../services/database_helper.dart';

class ActivitySelectionScreen extends StatefulWidget {
  final String mood;
  final DateTime? selectedDate; 
  final String time; 

  const ActivitySelectionScreen({
    super.key,
    required this.mood,
    this.selectedDate,
    required this.time,
  });

  @override
  _ActivitySelectionScreenState createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  final List<Map<String, dynamic>> activities = [
    {'label': 'Work', 'icon': Icons.work},
    {'label': 'Exercise', 'icon': Icons.fitness_center},
    {'label': 'Read', 'icon': Icons.book},
    {'label': 'Gaming', 'icon': Icons.videogame_asset},
    {'label': 'Movie', 'icon': Icons.movie},
    {'label': 'Shopping', 'icon': Icons.shopping_cart},
    {'label': 'Health', 'icon': Icons.health_and_safety},
    {'label': 'Music', 'icon': Icons.music_note},
    {'label': 'Relax', 'icon': Icons.spa},
    {'label': 'Travel', 'icon': Icons.airplanemode_active},
    {'label': 'Food', 'icon': Icons.fastfood},
    {'label': 'Socialize', 'icon': Icons.people},
  ];

  String? selectedActivity;

  void selectActivity(String label) {
    setState(() {
      selectedActivity = selectedActivity == label ? null : label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3CB371), size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Activities',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF3CB371), size: 30),
            onPressed: () async {
              await _saveActivitySelection(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodActivityScreen(
                    mood: widget.mood,
                    selectedActivity: selectedActivity,
                    selectedDate: widget.selectedDate,
                    selectedTime: widget.time, 
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'What have you achieved today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                itemCount: activities.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 30,
                ),
                itemBuilder: (context, index) {
                  String label = activities[index]['label'];
                  IconData icon = activities[index]['icon'];
                  bool isSelected = selectedActivity == label;

                  return GestureDetector(
                    onTap: () => selectActivity(label),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isSelected ? Colors.lightGreen : const Color(0xFF3CB371),
                          child: Icon(icon, size: 28, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                "${widget.selectedDate != null ? "${widget.selectedDate!.day}-${widget.selectedDate!.month}-${widget.selectedDate!.year}" : "Today"} at ${widget.time}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActivitySelection(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    Map<String, dynamic> activityData = {
      'mood': widget.mood,
      'activity': selectedActivity,
      'date': (widget.selectedDate ?? DateTime.now()).toIso8601String(),
      'time': widget.time,
    };
    await dbHelper.insertEntry(activityData);
  }
}
