import 'package:flutter/material.dart';
import 'activity_selection_screen.dart';
import '../services/database_helper.dart';

class MoodSelectionScreen extends StatelessWidget {
  final DateTime? selectedDate;

  const MoodSelectionScreen({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final DateTime displayDate = selectedDate ?? DateTime.now();
    final String displayTime = (selectedDate != null && selectedDate!.hour == 0 && selectedDate!.minute == 0)
        ? '00:00' 
        : TimeOfDay.now().format(context);

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF3CB371), size: 30),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Text(
              'How are you?',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
              },
              icon: const Icon(Icons.calendar_today, color: Color(0xFF3CB371)),
              label: Text(
                '${displayDate.day} ${_getMonthName(displayDate.month)} at $displayTime',
                style: const TextStyle(color: Color(0xFF3CB371)),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodIcon(
                  label: 'great',
                  color: const Color(0xFF388E3C),
                  icon: Icons.sentiment_very_satisfied,
                  size: 32,
                  onTap: () => _onMoodSelected(context, 'great', displayDate ),
                ),
                MoodIcon(
                  label: 'good',
                  color: const Color(0xFF93C765),
                  icon: Icons.sentiment_satisfied_alt,
                  size: 32,
                  onTap: () => _onMoodSelected(context, 'good', displayDate ),
                ),
                MoodIcon(
                  label: 'meh',
                  color: const Color(0xFFA5D6A7),
                  icon: Icons.sentiment_neutral,
                  size: 32,
                  onTap: () => _onMoodSelected(context, 'meh', displayDate ),
                ),
                MoodIcon(
                  label: 'bad',
                  color: const Color(0xFFE57580),
                  icon: Icons.sentiment_dissatisfied,
                  size: 32,
                  onTap: () => _onMoodSelected(context, 'bad', displayDate ),
                ),
                MoodIcon(
                  label: 'awful',
                  color: const Color(0xFFD05151),
                  icon: Icons.sentiment_very_dissatisfied,
                  size: 32,
                  onTap: () => _onMoodSelected(context, 'awful', displayDate ),
                ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  void _onMoodSelected(BuildContext context, String mood, DateTime date) async {
    final dbHelper = DatabaseHelper();
    final String time = (selectedDate != null && selectedDate!.hour == 0 && selectedDate!.minute == 0)
        ? "00:00"
        : TimeOfDay.now().format(context);

    Map<String, dynamic> moodData = {
      'mood': mood,
      'date': date.toIso8601String(),
      'time': time,
    };

    await dbHelper.insertEntry(moodData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitySelectionScreen(
          mood: mood,
          selectedDate: date,
          time: time, 
        ),
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

class MoodIcon extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const MoodIcon({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.size = 32,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: size,
            backgroundColor: color,
            child: Icon(
              icon,
              size: size * 1.5,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 16),
        ),
      ],
    );
  }
}
