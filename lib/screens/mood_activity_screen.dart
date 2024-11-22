import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class MoodActivityScreen extends StatefulWidget {
  final String mood;
  final String? selectedActivity;
  final DateTime? selectedDate;
  final String? selectedTime;

  const MoodActivityScreen({
    super.key,
    required this.mood,
    this.selectedActivity,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  _MoodActivityScreenState createState() => _MoodActivityScreenState();
}

class _MoodActivityScreenState extends State<MoodActivityScreen> {
  final TextEditingController _noteController = TextEditingController();
  File? _selectedImage;
  String? _selectedAssetImagePath;
  bool _isPublic = false; 
  bool _isAnonymous = false; 

  Future<void> _pickImageFromAssets() async {
    final List<String> assetImages = [
      'assets/forest_1.jpg',
      'assets/forest_2.jpg',
      'assets/lake_1.jpg',
      'assets/lake_2.jpg',
      'assets/park_1.jpg',
      'assets/park_2.jpg',
      'assets/waterfall_1.jpg',
      'assets/waterfall_2.jpg',
      'assets/Funeral.JPG',
      'assets/hua hin market.JPG',
      'assets/male student group.JPG',
      'assets/MeetFriends.JPG',
      'assets/my mom at beach.JPG',
      'assets/my sports team after the match.jpg',
      'assets/Party at my home.JPG',
      'assets/Peaceful garden.jpg',
      'assets/Playing guitar in the classroom.JPG',
      'assets/Pork BBQ party with my classmates.JPG',
      'assets/Scuba diving.jpg',
      'assets/Seaside horse.JPG',
      'assets/Take my younger brother to the airport..JPG',
      'assets/Taking a photo with friends at university.JPG',
      'assets/temple_1.jpg',
    ];

    String? selectedPath = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("เลือกภาพจาก Assets"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: assetImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(assetImages[index]);
                  },
                  child: Image.asset(assetImages[index], fit: BoxFit.cover),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedPath != null) {
      setState(() {
        _selectedAssetImagePath = selectedPath;
        _selectedImage = null;
      });
    }
  }

  void _onImageTapped() {
    if (_selectedAssetImagePath != null || _selectedImage != null) {
      _showRemoveImageDialog();
    } else {
      _pickImageFromAssets();
    }
  }

  void _showRemoveImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ลบรูปภาพ"),
          content: const Text("คุณต้องการลบรูปภาพนี้หรือไม่?"),
          actions: <Widget>[
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("ลบรูปภาพ"),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _selectedAssetImagePath = null;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onPublicToggle(bool value) {
    setState(() {
      _isPublic = value;
      if (!_isPublic) {
        _isAnonymous = false;
      }
    });
  }

  Future<void> _saveEntry(BuildContext context) async {
    if (!_isPublic && _isAnonymous) {
      setState(() {
        _isAnonymous = false;
      });
    }

    final dbHelper = DatabaseHelper();
    final DateTime date = widget.selectedDate ?? DateTime.now();
    final String formattedDate = date.toIso8601String().split("T").first;
    final String time = widget.selectedTime ?? TimeOfDay.now().format(context);
    final String? imagePath = _selectedAssetImagePath ?? _selectedImage?.path;

    Map<String, dynamic> entryData = {
      'mood': widget.mood,
      'activity': widget.selectedActivity,
      'note': _noteController.text,
      'image_path': imagePath,
      'date': formattedDate,
      'time': time,
      'is_public': _isPublic ? 1 : 0,
      'is_anonymous': _isAnonymous ? 1 : 0,
      'user_id': await _getUserId(),
    };

    await dbHelper.insertEntry(entryData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry saved successfully!')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Widget _buildImageWidget() {
    if (_selectedAssetImagePath != null) {
      return Image.asset(_selectedAssetImagePath!, fit: BoxFit.cover);
    } else if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.add_a_photo, color: Colors.white54, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayDate = widget.selectedDate != null
        ? "${widget.selectedDate!.day}-${widget.selectedDate!.month}-${widget.selectedDate!.year}"
        : "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";

    final String displayTime = widget.selectedTime ?? TimeOfDay.now().format(context);

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3CB371), size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF3CB371), size: 30),
            onPressed: () => _saveEntry(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImageFromAssets,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildImageWidget(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Date: $displayDate at $displayTime',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Feeling: ${widget.mood}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(_getMoodIcon(widget.mood), color: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Activity: ${widget.selectedActivity ?? 'No activity selected'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 10),
                if (widget.selectedActivity != null)
                  Icon(_getActivityIcon(widget.selectedActivity!), color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 15,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tap to add notes & thoughts...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Public',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              value: _isPublic,
              activeColor: const Color(0xFF3CB371),
              onChanged:_onPublicToggle,
            ),
            if (_isPublic)
              SwitchListTile(
                title: const Text(
                  'Share as Anonymous?',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                value: _isAnonymous,
                activeColor: const Color(0xFF3CB371),
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
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
}
