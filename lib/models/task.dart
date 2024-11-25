class Task {
  String id;
  String name;
  bool isCompleted;
  String day;
  String timeFrame;
  List<String> details;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.day,
    required this.timeFrame,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'day': day,
      'timeFrame': timeFrame,
      'details': details,
    };
  }

  static Task fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      name: map['name'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      day: map['day'] ?? '',
      timeFrame: map['timeFrame'] ?? '',
      details: List<String>.from(map['details'] ?? []),
    );
  }
}
