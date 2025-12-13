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
    return Subtask(
      id: json['id'],
      taskId: json['task_id'],
      title: json['title'],
      isDone: json['is_done'] ?? false,
    );
  }
}