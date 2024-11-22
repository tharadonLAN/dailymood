import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, int> moodCounts = {};
  Map<String, int> activityCounts = {};
  String averageMood = "Loading...";
  double positivePercent = 0;
  String mostFrequentMood = "";
  List<String> topActivities = [];
  Map<String, String> moodActivityPairs = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      try {
        Map<String, int> moods = await dbHelper.countEntriesByMood(userId);
        Map<String, int> activities = await dbHelper.countEntriesByActivity(userId);
        String avgMood = await dbHelper.getAverageMood(userId);
        double posPercent = await dbHelper.getPositiveEventPercentage(userId);
        String frequentMood = await dbHelper.getMostFrequentMoodForLatestMonth(userId);
        List<String> topThreeActivities = await dbHelper.getTopActivitiesForAllTime(userId);
        Map<String, String> moodActivityPairsData = await dbHelper.getMoodActivityPairsForAllTime(userId);

        setState(() {
          moodCounts = moods;
          activityCounts = activities;
          averageMood = avgMood;
          positivePercent = posPercent;
          mostFrequentMood = frequentMood;
          topActivities = topThreeActivities;
          moodActivityPairs = moodActivityPairsData;
        });
      } catch (error) {
        print("Error loading stats: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Your Stats',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF2C2C2C),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMoodStatCard(
            title: "Average Daily Mood",
            mood: averageMood,
            description: "Your average mood over time",
          ),
          const SizedBox(height: 16),
          _buildMoodPieChart(),
          const SizedBox(height: 16),
          _buildMoodStatCard(
            title: "Most Frequent Mood This Month",
            mood: mostFrequentMood,
            description: "Your most common mood this month",
          ),
          const SizedBox(height: 16),
          _buildMoodBarChart(),
          const SizedBox(height: 16),
          _buildActivityStatCard(
            title: "Most Frequent Activities",
            activities: topActivities,
            description: "Top 3 activities from your logs this month",
          ),
          const SizedBox(height: 16),
          _buildPosNegStat(),
          const SizedBox(height: 16),
          _buildMoodActivityPairs(),
        ],
      ),
    );
  }

  Widget _buildMoodStatCard({required String title, required String mood, required String description}) {
    return Card(
      color: _getMoodColor(mood),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_getMoodIcon(mood), color: const Color.fromARGB(255, 0, 0, 0), size: 24),
                const SizedBox(width: 8),
                Text(mood, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Color.fromARGB(179, 0, 0, 0), fontSize: 14)),
          ],
        ),
      ),
    );
  }



  Widget _buildMoodPieChart() {
    return Card(
      color: const Color(0xFF3C3C3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mood Distribution",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodBarChart() {
    return Card(
      color: const Color(0xFF3C3C3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mood Count for Latest Month",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  barGroups: _buildBarChartData(),
                  titlesData: FlTitlesData(show: false), 
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final List<PieChartSectionData> sections = [];

    
    moodCounts.forEach((mood, count) {
      sections.add(
        PieChartSectionData(
          color: _getMoodColor(mood),
          value: count.toDouble(),
          title: '$count', 
          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return sections;
  }

  List<BarChartGroupData> _buildBarChartData() {
    final List<BarChartGroupData> barGroups = [];
    int i = 0;

    moodCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)) 
      ..forEach((entry) {
        barGroups.add(
          BarChartGroupData(
            x: i++,
            barRods: [
              BarChartRodData(
                fromY: 0,
                toY: entry.value.toDouble(),
                color: _getMoodColor(entry.key),
                width: 20,
              ),
            ],
          ),
        );
      });

    return barGroups;
  }

  Widget _buildActivityStatCard({required String title, required List<String> activities, required String description}) {
    return Card(
      color: const Color(0xFF3C3C3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: activities.map((activity) {
                return Row(
                  children: [
                    Icon(_getActivityIcon(activity), color: Colors.lightGreenAccent, size: 20),
                    const SizedBox(width: 4),
                    Text(activity, style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPosNegStat() {
    return Card(
      color: const Color(0xFF3C3C3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Positive vs Negative Events",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Positive: ${positivePercent.toStringAsFixed(1)}% ",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "/ Negative: ${(100 - positivePercent).toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text("Percentage of positive activities", style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodActivityPairs() {
    return Card(
      color: const Color(0xFF3C3C3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mood-Activity Pairs",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  children: [
                    Icon(
                      _getMoodIcon(moodActivityPairs['mood'] ?? 'meh'), 
                      color: Colors.lightGreenAccent,
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Mood: ${moodActivityPairs['mood'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                // Icon สำหรับ Activity
                Column(
                  children: [
                    Icon(
                      _getActivityIcon(moodActivityPairs['activity'] ?? 'Work'), 
                      color: Colors.lightGreenAccent,
                      size: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Activity: ${moodActivityPairs['activity'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'great':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'meh':
        return Icons.sentiment_neutral;
      case 'bad':
        return Icons.sentiment_dissatisfied;
      case 'awful':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Work':
        return Icons.work;
      case 'Exercise':
        return Icons.fitness_center;
      case 'Read':
        return Icons.book;
      case 'Gaming':
        return Icons.videogame_asset;
      case 'Movie':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Health':
        return Icons.health_and_safety;
      case 'Music':
        return Icons.music_note;
      case 'Relax':
        return Icons.spa;
      case 'Travel':
        return Icons.airplanemode_active;
      case 'Food':
        return Icons.fastfood;
      case 'Socialize':
        return Icons.people;
      default:
        return Icons.help_outline;
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
        return Colors.grey;
    }
  }
}
