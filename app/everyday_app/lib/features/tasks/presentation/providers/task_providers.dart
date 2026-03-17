import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'package:everyday_app/features/tasks/data/models/subtask.dart';
import 'package:everyday_app/features/tasks/data/models/task.dart';
import 'package:everyday_app/features/tasks/data/models/task_assignement.dart';
import 'package:everyday_app/shared/models/user.dart';

import '../../data/models/task_with_details.dart';
import '../../domain/services/task_service.dart';
import '../../utils/task_temporal_ordering.dart';

DateTime _copyDateTime(DateTime value) {
  return DateTime.fromMillisecondsSinceEpoch(
    value.millisecondsSinceEpoch,
    isUtc: value.isUtc,
  );
}

AppUser _copyUser(AppUser user) {
  return AppUser(
    id: user.id,
    name: user.name,
    email: user.email,
    birthdate: user.birthdate == null ? null : _copyDateTime(user.birthdate!),
    avatarUrl: user.avatarUrl,
  );
}

HouseholdMember _copyMember(HouseholdMember member) {
  return HouseholdMember(
    id: member.id,
    userId: member.userId,
    householdId: member.householdId,
    role: member.role,
    isPersonnel: member.isPersonnel,
    personnelType: member.personnelType,
    profile: member.profile == null ? null : _copyUser(member.profile!),
  );
}

Task _copyTask(Task task) {
  return Task(
    id: task.id,
    householdId: task.householdId,
    roomId: task.roomId,
    title: task.title,
    description: task.description,
    taskDate: _copyDateTime(task.taskDate),
    timeFrom: task.timeFrom,
    timeTo: task.timeTo,
    repeatRule: task.repeatRule,
    visibility: task.visibility,
    createdBy: task.createdBy,
  );
}

Subtask _copySubtask(Subtask subtask) {
  return Subtask(
    id: subtask.id,
    taskId: subtask.taskId,
    title: subtask.title,
    isDone: subtask.isDone,
  );
}

TaskAssignment _copyAssignment(TaskAssignment assignment) {
  return TaskAssignment(
    id: assignment.id,
    taskId: assignment.taskId,
    memberId: assignment.memberId,
    roomId: assignment.roomId,
    status: assignment.status,
    note: assignment.note,
    completedAt: assignment.completedAt == null
        ? null
        : _copyDateTime(assignment.completedAt!),
    member: assignment.member == null ? null : _copyMember(assignment.member!),
  );
}

TaskWithDetails _copyTaskWithDetails(TaskWithDetails taskWithDetails) {
  return TaskWithDetails(
    task: _copyTask(taskWithDetails.task),
    subtasks: taskWithDetails.subtasks
        .map(_copySubtask)
        .toList(growable: false),
    assignments: taskWithDetails.assignments
        .map(_copyAssignment)
        .toList(growable: false),
  );
}

List<TaskWithDetails> _copyTaskList(Iterable<TaskWithDetails> tasks) {
  return tasks.map(_copyTaskWithDetails).toList(growable: false);
}

class OptimisticSubtaskOverridesNotifier
    extends StateNotifier<Map<String, bool>> {
  OptimisticSubtaskOverridesNotifier() : super(const {});

  void setOverride({required String subtaskId, required bool isDone}) {
    final current = state[subtaskId];
    if (current == isDone) {
      return;
    }

    state = <String, bool>{...state, subtaskId: isDone};
  }

  void clearOverride(String subtaskId) {
    if (!state.containsKey(subtaskId)) {
      return;
    }

    final next = <String, bool>{...state}..remove(subtaskId);
    state = next;
  }

  void reconcileWithTasks(List<TaskWithDetails> tasks) {
    if (state.isEmpty) {
      return;
    }

    final currentSubtaskStates = <String, bool>{};
    for (final task in tasks) {
      for (final subtask in task.subtasks) {
        currentSubtaskStates[subtask.id] = subtask.isDone;
      }
    }

    var changed = false;
    final next = <String, bool>{};

    for (final entry in state.entries) {
      final liveValue = currentSubtaskStates[entry.key];
      if (liveValue != null && liveValue == entry.value) {
        changed = true;
        continue;
      }

      next[entry.key] = entry.value;
    }

    if (changed || next.length != state.length) {
      state = next;
    }
  }
}

final optimisticSubtaskOverridesProvider =
    StateNotifierProvider<
      OptimisticSubtaskOverridesNotifier,
      Map<String, bool>
    >((ref) => OptimisticSubtaskOverridesNotifier());

List<TaskWithDetails> _applyOptimisticSubtaskOverrides({
  required Iterable<TaskWithDetails> tasks,
  required Map<String, bool> overrides,
}) {
  final copiedTasks = _copyTaskList(tasks);
  if (overrides.isEmpty) {
    return copiedTasks;
  }

  return copiedTasks
      .map((task) {
        var patched = false;
        final patchedSubtasks = task.subtasks
            .map((subtask) {
              final override = overrides[subtask.id];
              if (override == null || override == subtask.isDone) {
                return subtask;
              }

              patched = true;
              return Subtask(
                id: subtask.id,
                taskId: subtask.taskId,
                title: subtask.title,
                isDone: override,
              );
            })
            .toList(growable: false);

        if (!patched) {
          return task;
        }

        return TaskWithDetails(
          task: task.task,
          subtasks: patchedSubtasks,
          assignments: task.assignments,
        );
      })
      .toList(growable: false);
}

final taskServiceProvider = Provider<TaskService>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskService(taskRepository: repository);
});

final dailyTasksProvider = FutureProvider<List<TaskWithDetails>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  final tasks = await taskService.getTasksAssignedToCurrentMember();
  return sortTasksByTemporalOrder(tasks);
});

final tasksStreamProvider = StreamProvider<List<TaskWithDetails>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);

  if (householdId == null || householdId.isEmpty) {
    return const Stream<List<TaskWithDetails>>.empty();
  }

  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks(householdId).map((tasks) {
    final copiedTasks = sortTasksByTemporalOrder(_copyTaskList(tasks));
    if (kDebugMode) {
      final taskSignatures = copiedTasks
          .map(
            (task) =>
                '${task.task.id}[${task.subtasks.map((subtask) => '${subtask.id}:${subtask.isDone ? 1 : 0}').join('|')}]',
          )
          .join(', ');
      debugPrint(
        'TASK PROVIDER EMIT household=$householdId tasks=${copiedTasks.length} signatures=$taskSignatures',
      );
    }
    ref
        .read(optimisticSubtaskOverridesProvider.notifier)
        .reconcileWithTasks(copiedTasks);
    return copiedTasks;
  });
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

bool _isTaskAssignedToMember(TaskWithDetails task, String memberId) {
  return task.assignments.any((assignment) => assignment.memberId == memberId);
}

final homeDailyTasksProvider = Provider<AsyncValue<List<TaskWithDetails>>>((
  ref,
) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  final currentUser = ref.watch(currentUserProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);
  final optimisticSubtaskOverrides = ref.watch(
    optimisticSubtaskOverridesProvider,
  );

  if (householdId == null ||
      householdId.isEmpty ||
      currentUser == null ||
      currentUser.id.isEmpty) {
    return const AsyncValue<List<TaskWithDetails>>.data([]);
  }

  final today = DateTime.now();

  return tasksAsync.whenData((tasks) {
    final filtered = tasks
        .where((task) => task.task.householdId == householdId)
        .where((task) => _isSameCalendarDay(task.task.taskDate, today))
        .where((task) => _isTaskAssignedToUser(task, currentUser.id));

    return _applyOptimisticSubtaskOverrides(
      tasks: filtered,
      overrides: optimisticSubtaskOverrides,
    );
  });
});

final userTaskTimelineProvider =
    Provider.family<AsyncValue<List<TaskWithDetails>>, UserTaskTimelineQuery>((
      ref,
      query,
    ) {
      final householdId = ref.watch(currentHouseholdIdProvider);
      final tasksAsync = ref.watch(tasksStreamProvider);
      final optimisticSubtaskOverrides = ref.watch(
        optimisticSubtaskOverridesProvider,
      );

      if (householdId == null ||
          householdId.isEmpty ||
          query.targetUserId.isEmpty) {
        return const AsyncValue<List<TaskWithDetails>>.data([]);
      }

      return tasksAsync.whenData((tasks) {
        final filtered = tasks
            .where((task) => task.task.householdId == householdId)
            .where((task) => _isSameCalendarDay(task.task.taskDate, query.date))
            .where((task) => _isTaskAssignedToUser(task, query.targetUserId));

        return _applyOptimisticSubtaskOverrides(
          tasks: filtered,
          overrides: optimisticSubtaskOverrides,
        );
      });
    });

final taskRoomsProvider = FutureProvider<List<HouseholdRoom>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getAvailableRooms();
});

// =========================================================================
// NUOVO PROVIDER: TASKS DELLA SETTIMANA CORRENTE (Lunedì - Domenica)
// =========================================================================

bool _isDateInCurrentWeek(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  // Calcola quanti giorni sottrarre per arrivare a Lunedì (1 = Lunedì, 7 = Domenica)
  final daysSinceMonday = today.weekday - 1;
  final startOfWeek = today.subtract(Duration(days: daysSinceMonday));
  
  // Calcola la Domenica successiva (aggiungendo 6 giorni a Lunedì)
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  final taskDate = DateTime(date.year, date.month, date.day);
  
  // Ritorna true se la data della task è >= Lunedì e <= Domenica
  return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
         taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
}

final homeWeeklyTasksProvider = Provider<AsyncValue<List<TaskWithDetails>>>((
  ref,
) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  final currentUser = ref.watch(currentUserProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);
  final optimisticSubtaskOverrides = ref.watch(
    optimisticSubtaskOverridesProvider,
  );

  if (householdId == null ||
      householdId.isEmpty ||
      currentUser == null ||
      currentUser.id.isEmpty) {
    return const AsyncValue<List<TaskWithDetails>>.data([]);
  }

  return tasksAsync.whenData((tasks) {
    final filtered = tasks
        .where((task) => task.task.householdId == householdId)
        .where((task) => _isDateInCurrentWeek(task.task.taskDate))
        .where((task) => _isTaskAssignedToUser(task, currentUser.id))
        .toList(); // Serve una lista per l'override

    return _applyOptimisticSubtaskOverrides(
      tasks: filtered,
      overrides: optimisticSubtaskOverrides,
    );
  });
});

// =========================================================================
// PROVIDER: TASKS DI UNA SETTIMANA SPECIFICA (Per la WeekTasksScreen)
// =========================================================================

bool _isDateInSpecificWeek(DateTime date, DateTime weekReference) {
  final reference = DateTime(weekReference.year, weekReference.month, weekReference.day);
  final daysSinceMonday = reference.weekday - 1;
  final startOfWeek = reference.subtract(Duration(days: daysSinceMonday));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  final taskDate = DateTime(date.year, date.month, date.day);
  
  return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
         taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
}

// Usiamo .family per poter passare la data selezionata dall'utente
final weeklyTasksFamilyProvider = Provider.family<AsyncValue<List<TaskWithDetails>>, DateTime>((
  ref, 
  selectedWeek
) {
  final householdId = ref.watch(currentHouseholdIdProvider);
  final currentUser = ref.watch(currentUserProvider);
  final tasksAsync = ref.watch(tasksStreamProvider);
  final optimisticSubtaskOverrides = ref.watch(optimisticSubtaskOverridesProvider);

  if (householdId == null || householdId.isEmpty || currentUser == null || currentUser.id.isEmpty) {
    return const AsyncValue<List<TaskWithDetails>>.data([]);
  }

  return tasksAsync.whenData((tasks) {
    final filtered = tasks
        .where((task) => task.task.householdId == householdId)
        .where((task) => _isDateInSpecificWeek(task.task.taskDate, selectedWeek))
        .where((task) => _isTaskAssignedToUser(task, currentUser.id))
        .toList();

    return _applyOptimisticSubtaskOverrides(
      tasks: filtered,
      overrides: optimisticSubtaskOverrides,
    );
  });
});

class WeeklyTasksByMemberQuery {
  final DateTime selectedWeek;
  final String targetMemberId;

  const WeeklyTasksByMemberQuery({
    required this.selectedWeek,
    required this.targetMemberId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyTasksByMemberQuery &&
        other.targetMemberId == targetMemberId &&
        other.selectedWeek.year == selectedWeek.year &&
        other.selectedWeek.month == selectedWeek.month &&
        other.selectedWeek.day == selectedWeek.day;
  }

  @override
  int get hashCode {
    return Object.hash(
      targetMemberId,
      selectedWeek.year,
      selectedWeek.month,
      selectedWeek.day,
    );
  }
}

final weeklyTasksByMemberFamilyProvider =
    Provider.family<AsyncValue<List<TaskWithDetails>>, WeeklyTasksByMemberQuery>(
      (ref, query) {
        final householdId = ref.watch(currentHouseholdIdProvider);
        final tasksAsync = ref.watch(tasksStreamProvider);
        final optimisticSubtaskOverrides = ref.watch(
          optimisticSubtaskOverridesProvider,
        );

        final memberId = query.targetMemberId.trim();
        if (householdId == null || householdId.isEmpty || memberId.isEmpty) {
          return const AsyncValue<List<TaskWithDetails>>.data([]);
        }

        return tasksAsync.whenData((tasks) {
          final filtered = tasks
              .where((task) => task.task.householdId == householdId)
              .where(
                (task) => _isDateInSpecificWeek(task.task.taskDate, query.selectedWeek),
              )
              .where((task) => _isTaskAssignedToMember(task, memberId))
              .toList();

          return _applyOptimisticSubtaskOverrides(
            tasks: filtered,
            overrides: optimisticSubtaskOverrides,
          );
        });
      },
    );