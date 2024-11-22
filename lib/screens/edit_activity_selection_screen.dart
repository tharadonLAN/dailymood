import 'package:flutter/material.dart';


class EditActivitySelectionScreen extends StatefulWidget {
  final String? initialActivity; 

  const EditActivitySelectionScreen({super.key, required this.initialActivity});

  @override
  _EditActivitySelectionScreenState createState() => _EditActivitySelectionScreenState();
}

class _EditActivitySelectionScreenState extends State<EditActivitySelectionScreen> {
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

  @override
  void initState() {
    super.initState();
    selectedActivity = widget.initialActivity;
  }

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
          icon: const Icon(Icons.close, color: Color(0xFF3CB371), size: 30),
          onPressed: () => Navigator.of(context).pop(), // Close without saving
        ),
        title: const Text(
          'Edit Activity',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF3CB371), size: 30),
            onPressed: () {
              Navigator.of(context).pop(selectedActivity);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Select an activity for this entry:',
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
          ],
        ),
      ),
    );
  }
}
