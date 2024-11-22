import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'mood_selection_screen.dart';
import 'view_entries_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;
  Map<String, Map<int, Color>> moodColorsPerMonth = {};

  @override
  void initState() {
    super.initState();
    _loadMoodColors();
    _scrollToCurrentMonth();
  }

  Future<void> _loadMoodColors() async {
    final dbHelper = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      Map<String, Map<int, Color>> yearMoodMap = {};

      for (int month = 1; month <= 12; month++) {
        final entries = await dbHelper.getLatestMoodPerDay(userId, month, currentYear);
        Map<int, Color> dayMoodMap = {};

        for (var entry in entries) {
          final dateParts = entry['date'].split('-');
          final day = int.parse(dateParts[2]);
          final mood = entry['mood'];
          dayMoodMap[day] = _getMoodColor(mood);
        }

        yearMoodMap['$currentYear-$month'] = dayMoodMap;
      }

      setState(() {
        moodColorsPerMonth = yearMoodMap;
      });
    }
  }

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
        return Colors.transparent;
    }
  }

  void _scrollToCurrentMonth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final double position = (currentMonth - 1) * 500.0; 
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showEmptyDateDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("No entries found"),
          content: const Text("No entry for this day. Would you like to create a new entry?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Create Entry"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoodSelectionScreen(
                      selectedDate: DateTime(date.year, date.month, date.day),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        centerTitle: true,
        title: const Text(
          'DailyMood Calendar',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: 12,
        itemBuilder: (context, index) {
          int month = index + 1;
          return _buildMonthCalendar(month);
        },
      ),
    );
  }

  Widget _buildMonthCalendar(int month) {
    final lastDayOfMonth = DateTime(currentYear, month + 1, 0).day;
    final moodColors = moodColorsPerMonth['$currentYear-$month'] ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            '${_getMonthName(month)} $currentYear',
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lastDayOfMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemBuilder: (context, index) {
            final day = index + 1;
            final moodColor = moodColors[day] ?? Colors.transparent;

            return GestureDetector(
              onTap: () {
                final selectedDate = DateTime(currentYear, month, day);
                if (moodColor == Colors.transparent) {
                  _showEmptyDateDialog(selectedDate);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewEntriesScreen(date: selectedDate),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: moodColor,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
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
