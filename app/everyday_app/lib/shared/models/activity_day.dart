class ActivityDay {
  final String id;
  final String memberId;
  final DateTime day;
  final bool hasTasks;

  ActivityDay({
    required this.id,
    required this.memberId,
    required this.day,
    required this.hasTasks,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      id: json['id'],
      memberId: json['member_id'],
      day: DateTime.parse(json['day']),
      hasTasks: json['has_tasks'] ?? true, // Il default del DB è true
    );
  }
}