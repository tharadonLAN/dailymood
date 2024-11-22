import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class PostDetailScreen extends StatefulWidget {
  final int entryId;
  final String username;

  const PostDetailScreen({super.key, required this.entryId, required this.username});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Set<String> selectedReactions = {};
  String? mood;
  String? activity;
  String? note;
  String? imagePath;
  bool isAsset = false;
  Map<String, int> reactions = {
    '❤️': 0,
    '😊': 0,
    '😢': 0,
    '😮': 0,
  };

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
        mood = entry['mood'];
        activity = entry['activity'];
        note = entry['note'];
        imagePath = entry['image_path'];
        _loadReactions(entry['reactions']);
        isAsset = imagePath != null && imagePath!.contains('assets/');
      });
    }
  }

  void _loadReactions(String? reactionsJson) {
    if (reactionsJson != null) {
      final reactionData = Map<String, int>.from(jsonDecode(reactionsJson));
      setState(() {
        reactions = reactionData;
      });
    }
  }

  void _toggleReaction(String emoji) {
    setState(() {
      if (selectedReactions.contains(emoji)) {
        reactions[emoji] = (reactions[emoji] ?? 0) - 1;
        selectedReactions.remove(emoji);
      } else {
        reactions[emoji] = (reactions[emoji] ?? 0) + 1;
        selectedReactions.add(emoji);
      }
    });
  }

  Future<void> _saveReactions() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateReactions(widget.entryId, reactions);
  }

  @override
  void dispose() {
    _saveReactions();
    super.dispose();
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
      onTap: _showFullImage,
      child: isAsset
          ? Image.asset(imagePath!, fit: BoxFit.cover)
          : Image.file(File(imagePath!), fit: BoxFit.cover),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C), size: 36),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Details',
          style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Shared by: ${widget.username}",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 10),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getMoodIcon(mood ?? 'meh'), color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      mood ?? 'No mood selected',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(_getActivityIcon(activity ?? ''), color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      activity ?? 'No activity selected',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
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
              child: Text(
                note ?? 'No note added',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Spacer(),
            _buildReactionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: reactions.entries.map((entry) {
            return GestureDetector(
              onTap: () => _toggleReaction(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 24,
                        color: selectedReactions.contains(entry.key) ? Colors.yellow : Colors.white,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Text(
          "${reactions.values.reduce((a, b) => a + b)} reactions",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}
