import 'package:flutter/foundation.dart';

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

    final subtaskRows = _mapList(json['subtask']);
    final subtasks = <Subtask>[];
    for (final row in subtaskRows) {
      try {
        subtasks.add(Subtask.fromJson(row));
      } catch (error) {
        if (kDebugMode) {
          final subtaskId = row['id']?.toString() ?? '-';
          debugPrint(
            'TASK_WITH_DETAILS_SKIP_SUBTASK task_id=${task.id} subtask_id=$subtaskId error=$error',
          );
        }
      }
    }

    final assignmentRows = _mapList(json['task_assignment']);
    final assignments = <TaskAssignment>[];
    for (final row in assignmentRows) {
      try {
        assignments.add(TaskAssignment.fromJson(row));
      } catch (error) {
        if (kDebugMode) {
          final assignmentId = row['id']?.toString() ?? '-';
          debugPrint(
            'TASK_WITH_DETAILS_SKIP_ASSIGNMENT task_id=${task.id} assignment_id=$assignmentId error=$error',
          );
        }
      }
    }

    return TaskWithDetails(
      task: task,
      subtasks: subtasks,
      assignments: assignments,
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
