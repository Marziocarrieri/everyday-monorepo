class AppNotification {
  final String id;
  final String householdId;
  final String title;
  final String? description;
  final String type; // 'TASK', 'REMINDER', 'SYSTEM'...
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.householdId,
    required this.title,
    this.description,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      householdId: json['household_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      isRead: json['read'] ?? false, // 'read' è il campo nel DB
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}