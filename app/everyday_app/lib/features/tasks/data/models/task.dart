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
    final id = _asString(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Task row is missing id');
    }

    final householdId = _asString(json['household_id']);
    if (householdId.isEmpty) {
      throw const FormatException('Task row is missing household_id');
    }

    final parsedDate = _parseDate(json['task_date']);
    if (parsedDate == null) {
      throw const FormatException('Task row has invalid task_date');
    }

    return Task(
      id: id,
      householdId: householdId,
      roomId: _asNullableString(json['room_id']),
      title: _asString(json['title']),
      description: _asNullableString(json['description']),
      taskDate: parsedDate,
      timeFrom: _asNullableString(json['time_from']),
      timeTo: _asNullableString(json['time_to']),
      repeatRule: _asString(json['repeat_rule'], fallback: 'NONE'),
      visibility: _asString(json['visibility'], fallback: 'ALL'),
      createdBy: _asNullableString(json['created_by']),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString();
    return normalized;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}