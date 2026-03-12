import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';

import '../../data/models/task_with_details.dart';
import '../../domain/services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskService(taskRepository: repository);
});

final dailyTasksProvider = FutureProvider<List<TaskWithDetails>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getTasksAssignedToCurrentMember();
});

final tasksStreamProvider = StreamProvider<List<TaskWithDetails>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);

  if (householdId == null || householdId.isEmpty) {
    return const Stream<List<TaskWithDetails>>.empty();
  }

  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks(householdId);
});

class UserTaskTimelineQuery {
  final DateTime date;
  final String targetUserId;

  const UserTaskTimelineQuery({required this.date, required this.targetUserId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTaskTimelineQuery &&
        other.targetUserId == targetUserId &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  @override
  int get hashCode {
    return Object.hash(targetUserId, date.year, date.month, date.day);
  }
}

bool _isSameCalendarDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _isTaskAssignedToUser(TaskWithDetails task, String userId) {
  return task.assignments.any(
    (assignment) => assignment.member?.userId == userId,
  );
}

final homeDailyTasksProvider = Provider<AsyncValue<List<TaskWithDetails>>>((
  ref,
) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  final currentUser = ref.watch(currentUserProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);

  if (householdId == null ||
      householdId.isEmpty ||
      currentUser == null ||
      currentUser.id.isEmpty) {
    return const AsyncValue<List<TaskWithDetails>>.data([]);
  }

  final today = DateTime.now();

  return tasksAsync.whenData((tasks) {
    return tasks
        .where((task) => task.task.householdId == householdId)
        .where((task) => _isSameCalendarDay(task.task.taskDate, today))
        .where((task) => _isTaskAssignedToUser(task, currentUser.id))
        .toList();
  });
});

final userTaskTimelineProvider =
    Provider.family<AsyncValue<List<TaskWithDetails>>, UserTaskTimelineQuery>((
      ref,
      query,
    ) {
      final householdId = ref.watch(currentHouseholdIdProvider);
      final tasksAsync = ref.watch(tasksStreamProvider);

      if (householdId == null ||
          householdId.isEmpty ||
          query.targetUserId.isEmpty) {
        return const AsyncValue<List<TaskWithDetails>>.data([]);
      }

      return tasksAsync.whenData((tasks) {
        return tasks
            .where((task) => task.task.householdId == householdId)
            .where((task) => _isSameCalendarDay(task.task.taskDate, query.date))
            .where((task) => _isTaskAssignedToUser(task, query.targetUserId))
            .toList();
      });
    });

final taskRoomsProvider = FutureProvider<List<HouseholdRoom>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getAvailableRooms();
});
