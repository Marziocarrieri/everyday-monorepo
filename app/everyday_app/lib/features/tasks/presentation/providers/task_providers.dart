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

final taskRoomsProvider = FutureProvider<List<HouseholdRoom>>((ref) async {
  final taskService = ref.watch(taskServiceProvider);
  return taskService.getAvailableRooms();
});
