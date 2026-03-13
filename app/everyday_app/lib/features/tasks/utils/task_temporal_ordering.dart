import 'package:everyday_app/features/tasks/data/models/task_with_details.dart';

int? _parseStartMinutes(String? rawTime) {
  if (rawTime == null || rawTime.trim().isEmpty) {
    return null;
  }

  final chunks = rawTime.split(':');
  if (chunks.length < 2) {
    return null;
  }

  final hour = int.tryParse(chunks[0]);
  final minute = int.tryParse(chunks[1]);
  if (hour == null || minute == null) {
    return null;
  }

  return (hour * 60) + minute;
}

int compareTaskTemporalOrder(TaskWithDetails left, TaskWithDetails right) {
  final leftStartMinutes = _parseStartMinutes(left.task.timeFrom);
  final rightStartMinutes = _parseStartMinutes(right.task.timeFrom);

  final leftHasStartTime = leftStartMinutes != null;
  final rightHasStartTime = rightStartMinutes != null;

  // Untimed tasks are shown first.
  if (!leftHasStartTime && rightHasStartTime) {
    return -1;
  }
  if (leftHasStartTime && !rightHasStartTime) {
    return 1;
  }

  if (leftHasStartTime && rightHasStartTime) {
    final byStartTime = leftStartMinutes.compareTo(rightStartMinutes);
    if (byStartTime != 0) {
      return byStartTime;
    }
  }

  final byDate = left.task.taskDate.compareTo(right.task.taskDate);
  if (byDate != 0) {
    return byDate;
  }

  return left.task.id.compareTo(right.task.id);
}

List<TaskWithDetails> sortTasksByTemporalOrder(
  Iterable<TaskWithDetails> tasks,
) {
  final sorted = tasks.toList(growable: false);
  sorted.sort(compareTaskTemporalOrder);
  return sorted;
}
