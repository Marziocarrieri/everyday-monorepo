import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/providers/app_providers.dart';

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
