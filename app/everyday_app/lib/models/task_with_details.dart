import 'subtask.dart';
import 'task.dart';
import 'task_assignement.dart';

class TaskWithDetails {
  final Task task;
  final List<Subtask> subtasks;
  final List<TaskAssignment> assignments;

  const TaskWithDetails({
    required this.task,
    required this.subtasks,
    required this.assignments,
  });

  factory TaskWithDetails.fromJson(Map<String, dynamic> json) {
    final task = Task.fromJson(json);

    final subtaskRows = List<Map<String, dynamic>>.from(
      (json['subtask'] as List?) ?? const [],
    );

    final assignmentRows = List<Map<String, dynamic>>.from(
      (json['task_assignment'] as List?) ?? const [],
    );

    return TaskWithDetails(
      task: task,
      subtasks: subtaskRows.map(Subtask.fromJson).toList(),
      assignments: assignmentRows.map(TaskAssignment.fromJson).toList(),
    );
  }
}
