import 'dart:io';
import 'package:flutter/material.dart';
import 'post_detail_screen.dart';
import '../services/database_helper.dart';

class PublicFeedScreen extends StatefulWidget {
  const PublicFeedScreen({super.key});

  @override
  _PublicFeedScreenState createState() => _PublicFeedScreenState();
}

class _PublicFeedScreenState extends State<PublicFeedScreen> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String? filterMood;
  String? filterActivity; 

  @override
  void initState() {
    super.initState();
    _loadPublicPosts();
  }

  Future<void> _loadPublicPosts() async {
    setState(() {
      isLoading = true;
    });

    final dbHelper = DatabaseHelper();
    final publicPosts = await dbHelper.getPublicEntries();

    setState(() {
      posts = publicPosts;
      isLoading = false;
    });
  }

  void _applyFilters(String? mood, String? activity) async {
    setState(() {
      isLoading = true;
    });

    final dbHelper = DatabaseHelper();
    final filteredPosts = await dbHelper.getPublicEntries(mood: mood, activity: activity);

    setState(() {
      posts = filteredPosts;
      isLoading = false;
    });
  }


  void _navigateToPostDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          entryId: post['id'],
          username: post['is_anonymous'] == 1 ? 'Anonymous' : post['username'],
        ),
      ),
    ).then((_) => _loadPublicPosts());
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
              title: const Text("Filter Posts"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: const Text("Select Mood"),
                    value: selectedMood,
                    isExpanded: true,
                    items: ['great', 'good', 'meh', 'bad', 'awful']
                        .map((mood) => DropdownMenuItem<String>(
                              value: mood,
                              child: Container(
                                width: double.infinity, 
                                color: _getMoodColor(mood), 
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Text(
                                  mood,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMood = value;
                      });
                    },
                    dropdownColor: Colors.white, 
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    hint: const Text("Select Activity"),
                    value: selectedActivity,
                    isExpanded: true,
                    items: [
                      'Work', 'Exercise', 'Read', 'Gaming', 'Movie', 'Shopping', 'Health', 'Music', 'Relax', 'Travel', 'Food', 'Socialize'
                    ].map((activity) => DropdownMenuItem<String>(
                          value: activity,
                          child: Text(activity, style: const TextStyle(color: Colors.black)),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedActivity = value;
                      });
                    },
                    dropdownColor: Colors.white,
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
                    _applyFilters(null, null);
                  },
                ),
                TextButton(
                  child: const Text("Search"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFilters(selectedMood, selectedActivity);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Share Feed',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF3CB371)),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2C2C2C),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(
                  child: Text(
                    'No public posts available.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return GestureDetector(
                      onTap: () => _navigateToPostDetail(post),
                      child: _buildPostCard(post),
                    );
                  },
                ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      height: 160, 
      decoration: BoxDecoration(
        color: _getMoodColor(post['mood']),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post['image_path'] != null && post['image_path'].isNotEmpty)
                post['image_path'].contains('assets/')
                    ? Image.asset(post['image_path'], width: 50, height: 50, fit: BoxFit.cover)
                    : Image.file(File(post['image_path']), width: 50, height: 50, fit: BoxFit.cover)
              else
                const Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post['activity'] ?? "No activity",
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                post['date'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post['note'] ?? "No notes available",
            style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
            maxLines: 2,  
            overflow: TextOverflow.ellipsis, 
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              post['is_anonymous'] == 1 ? 'Anonymous' : (post['username'] ?? 'Unknown User'),
              style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
