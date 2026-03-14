class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isDone;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Subtask row is missing id');
    }

    final taskId = _asString(json['task_id']);
    if (taskId.isEmpty) {
      throw const FormatException('Subtask row is missing task_id');
    }

    return Subtask(
      id: id,
      taskId: taskId,
      title: _asString(json['title']),
      isDone: _asBool(json['is_done']),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null) return false;

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'y';
  }
}