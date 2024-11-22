class MoodEntry {
  final int? id; 
  final int userId; 
  final String mood; 
  final String? activity; 
  final String? note; 
  final String? imagePath; 
  final String date; 
  final String time; 

  MoodEntry({
    this.id,
    required this.userId,
    required this.mood,
    this.activity,
    this.note,
    this.imagePath,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'mood': mood,
      'activity': activity,
      'note': note,
      'image_path': imagePath,
      'date': date,
      'time': time,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      userId: map['user_id'],
      mood: map['mood'],
      activity: map['activity'],
      note: map['note'],
      imagePath: map['image_path'],
      date: map['date'],
      time: map['time'],
    );
  }
}
