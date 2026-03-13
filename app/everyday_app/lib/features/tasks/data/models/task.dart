class Task {
  final String id;
  final String householdId;
  final String? roomId;
  final String title;
  final String? description;
  final DateTime taskDate;
  // Teniamo gli orari come stringa del DB ("14:30:00") e li convertiremo nella UI.
  final String? timeFrom; 
  final String? timeTo;
  final String repeatRule; // 'DAILY', 'WEEKLY', 'MONTHLY'
  final String visibility; // 'ALL', 'HOST_ONLY'...
  final String? createdBy; // household_member id of creator

  Task({
    required this.id,
    required this.householdId,
    this.roomId,
    required this.title,
    this.description,
    required this.taskDate,
    this.timeFrom,
    this.timeTo,
    required this.repeatRule,
    required this.visibility,
    this.createdBy,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      householdId: json['household_id'],
      roomId: json['room_id'],
      title: json['title'],
      description: json['description'],
      taskDate: DateTime.parse(json['task_date']),
      timeFrom: json['time_from'],
      timeTo: json['time_to'],
      repeatRule: json['repeat_rule'] ?? 'NONE',
      visibility: json['visibility'] ?? 'ALL',
      createdBy: json['created_by'] as String?,
    );
  }
}