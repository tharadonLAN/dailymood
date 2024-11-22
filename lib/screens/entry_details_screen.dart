import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'Edit_Activity_Selection_Screen.dart';

class EntryDetailsScreen extends StatefulWidget {
  final int entryId;

  const EntryDetailsScreen({super.key, required this.entryId});

  @override
  _EntryDetailsScreenState createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  bool _isEditing = false;
  String? selectedMood;
  String? selectedActivity;
  String? note;
  String? imagePath;
  bool isAsset = false;
  final TextEditingController _noteController = TextEditingController();
  bool _isPublic = false; 
  bool _isAnonymous = false; 

  @override
  void initState() {
    super.initState();
    _loadEntryDetails();
  }

  Future<void> _loadEntryDetails() async {
    final dbHelper = DatabaseHelper();
    final entry = await dbHelper.getEntryById(widget.entryId);

    if (entry != null) {
      setState(() {
        selectedMood = entry['mood'];
        selectedActivity = entry['activity'];
        note = entry['note'];
        imagePath = entry['image_path'];
        _noteController.text = note ?? '';
        _isPublic = entry['is_public'] == 1;
        _isAnonymous = entry['anonymous'] == 1;

        if (imagePath != null && imagePath!.contains('assets/')) {
          isAsset = true;
        }
      });
    }
  }

  Widget _buildImageWidget() {
    if (imagePath == null) {
      return const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 50,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_isEditing) {
          _showRemoveImageDialog(); 
        } else {
          _showFullImage(); 
        }
      },
      child: isAsset
          ? Image.asset(imagePath!, fit: BoxFit.cover)
          : Image.file(File(imagePath!), fit: BoxFit.cover),
    );
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
                  imagePath = null;
                  isAsset = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: isAsset
                ? Image.asset(imagePath!, fit: BoxFit.contain)
                : Image.file(File(imagePath!), fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _deleteEntry() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteEntry(widget.entryId);
    Navigator.pop(context);
  }

  Future<void> _saveEntry() async {
    if (!_isPublic) {
      _isAnonymous = false; 
    }

    final dbHelper = DatabaseHelper();
    await dbHelper.updateEntry(widget.entryId, {
      'mood': selectedMood,
      'activity': selectedActivity,
      'note': _noteController.text,
      'image_path': imagePath,
      'is_public': _isPublic ? 1 : 0,
      'is_anonymous': _isAnonymous ? 1 : 0,
    });
    _toggleEditMode();
  }


  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIcon() {
    return GestureDetector(
      onTap: _isEditing ? _showMoodDropdown : null, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mood:',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                selectedMood ?? 'No mood selected',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(width: 10),
              Icon(
                _getMoodIcon(selectedMood ?? 'meh'),
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoodDropdown() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Mood"),
          content: DropdownButton<String>(
            value: selectedMood,
            items: ['great', 'good', 'meh', 'bad', 'awful']
                .map((mood) => DropdownMenuItem(
                      value: mood,
                      child: Text(mood),
                    ))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedMood = newValue;
              });
              Navigator.of(context).pop(); 
            },
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3CB371),
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 36),
                onPressed: _showDeleteConfirmationDialog,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C), size: 36),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Entry Details',
          style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF2C2C2C), size: 36),
              onPressed: _saveEntry,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2C2C2C), size: 36),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildImageWidget(),
            ),
            const SizedBox(height: 20),
            // Mood and Activity with Icons
            _buildMoodIcon(),
            const SizedBox(height: 10),
            _buildActivityIcon(),
            const SizedBox(height: 20),
            // Note Section
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isEditing
                  ? TextField(
                      controller: _noteController,
                      maxLines: 15,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Tap to add notes & thoughts...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    )
                  : Text(
                      note ?? 'No note added',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            // Public Toggle Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Publicly',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: _isEditing
                      ? (value) {
                          setState(() {
                            _isPublic = value;
                            if (!_isPublic) _isAnonymous = false;
                          });
                        }
                      : null,
                  activeColor: const Color(0xFF3CB371),
                ),
              ],
            ),
            // Anonymous Toggle Button
            if (_isPublic)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Share Anonymously',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          }
                        : null,
                    activeColor: const Color(0xFF3CB371),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildActivityIcon() {
    return GestureDetector(
      onTap: _isEditing ? _selectActivity : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Activity:',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                selectedActivity ?? 'No activity selected',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              if (selectedActivity != null) ...[
                const SizedBox(width: 5),
                Icon(
                  _getActivityIcon(selectedActivity!),
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  void _selectActivity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivitySelectionScreen(
          initialActivity: selectedActivity,
        ),
      ),
    );

    setState(() {
      selectedActivity = result; 
    });
  }
}
