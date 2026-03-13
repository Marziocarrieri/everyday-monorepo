import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../models/task_with_details.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import '../../../../shared/repositories/supabase_client.dart';

class TaskRepository {
  StreamController<List<TaskWithDetails>>? _activeWatchTasksController;
  Stream<List<TaskWithDetails>>? _activeWatchTasksStream;
  StreamSubscription<List<Map<String, dynamic>>>? _activeTaskSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _activeAssignmentSubscription;
  RealtimeChannel? _activeSubtaskRealtimeChannel;
  RealtimeChannel? _activeTaskRealtimeChannel;
  String? _activeWatchHouseholdId;
  String? _lastSnapshotSignature;

  void _clearActiveWatchState() {
    _activeWatchTasksController = null;
    _activeWatchTasksStream = null;
    _activeTaskSubscription = null;
    _activeAssignmentSubscription = null;
    _activeSubtaskRealtimeChannel = null;
    _activeTaskRealtimeChannel = null;
    _activeWatchHouseholdId = null;
    _lastSnapshotSignature = null;
  }

  Future<void> _disposeActiveWatch({
    StreamController<List<TaskWithDetails>>? controller,
    StreamSubscription<List<Map<String, dynamic>>>? taskSubscription,
    StreamSubscription<List<Map<String, dynamic>>>? assignmentSubscription,
    RealtimeChannel? taskRealtimeChannel,
    RealtimeChannel? subtaskRealtimeChannel,
    bool closeController = true,
  }) async {
    await taskSubscription?.cancel();
    await assignmentSubscription?.cancel();
    if (taskRealtimeChannel != null) {
      await supabase.removeChannel(taskRealtimeChannel);
    }
    if (subtaskRealtimeChannel != null) {
      await supabase.removeChannel(subtaskRealtimeChannel);
    }
    if (closeController && controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  bool _isMissingColumnError(Object error, String columnName) {
    final message = error.toString().toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('column') || message.contains('schema cache'));
  }

  // 1. SALVA UN TASK
  Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      final res = await supabase
          .from('tasks')
          .insert(taskData)
          .select('id')
          .single();

      return res['id'];
    } catch (error) {
      final includesRoomId = taskData.containsKey('room_id');
      if (!includesRoomId || !_isMissingColumnError(error, 'room_id')) {
        rethrow;
      }

      debugPrint('room_id not available, creating task without room: $error');
      final fallbackPayload = Map<String, dynamic>.from(taskData)
        ..remove('room_id');

      final res = await supabase
          .from('tasks')
          .insert(fallbackPayload)
          .select('id')
          .single();

      return res['id'];
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> taskData) async {
    try {
      await supabase.from('tasks').update(taskData).eq('id', taskId);
    } catch (error) {
      final includesRoomId = taskData.containsKey('room_id');
      if (!includesRoomId || !_isMissingColumnError(error, 'room_id')) {
        rethrow;
      }

      debugPrint('room_id not available, updating task without room: $error');
      final fallbackPayload = Map<String, dynamic>.from(taskData)
        ..remove('room_id');
      await supabase.from('tasks').update(fallbackPayload).eq('id', taskId);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await supabase.from('subtask').delete().eq('task_id', taskId);
    await supabase.from('task_assignment').delete().eq('task_id', taskId);
    await supabase.from('tasks').delete().eq('id', taskId);
  }

  // 2. SCARICA I TASK DI UN GIORNO
  Future<List<Task>> getTasksByDate(String householdId, DateTime date) async {
    // Convertiamo la data in stringa "2025-12-13" perché il DB capisce solo testo
    final dateString = date.toIso8601String().split('T')[0];

    final response = await supabase
        .from('tasks')
        .select() // Prendi tutto
        .eq('household_id', householdId) // Filtra per casa
        .eq('task_date', dateString) // Filtra per data esatta
        .order('created_at'); // Mettili in ordine cronologico

    // Trasformiamo la lista di dati grezzi in una lista di oggetti Task
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  // 3. ASSEGNA TASK
  Future<void> assignTask(String taskId, String memberId) async {
    await supabase.from('task_assignment').insert({
      'task_id': taskId,
      'member_id': memberId,
      'status': 'TODO',
    });
  }

  // Serve per dire: "L'assegnazione X ora è 'DONE' o 'SKIPPED'"
  Future<void> updateAssignmentStatus(
    String assignmentId,
    String newStatus,
  ) async {
    await supabase
        .from('task_assignment') // Andiamo nella tabella delle assegnazioni
        .update({'status': newStatus}) // Cambiamo la colonna status
        .eq('id', assignmentId);
  }

  Future<List<TaskWithDetails>> getTasksForHousehold(String householdId) async {
    final response = await supabase
        .from('tasks')
        .select('''
          *,
          subtask(*),
          task_assignment(*, household_member(*, users_profile(*)))
        ''')
        .eq('household_id', householdId)
        .order('task_date', ascending: true)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(
      response,
    ).map(TaskWithDetails.fromJson).toList();
  }

  Stream<List<TaskWithDetails>> watchTasks(String householdId) {
    final existingController = _activeWatchTasksController;
    final existingStream = _activeWatchTasksStream;
    if (existingController != null &&
        !existingController.isClosed &&
        existingStream != null &&
        _activeWatchHouseholdId == householdId) {
      return existingStream;
    }

    if (existingController != null ||
        _activeTaskSubscription != null ||
        _activeAssignmentSubscription != null ||
        _activeSubtaskRealtimeChannel != null ||
        _activeTaskRealtimeChannel != null) {
      final staleController = _activeWatchTasksController;
      final staleTaskSubscription = _activeTaskSubscription;
      final staleAssignmentSubscription = _activeAssignmentSubscription;
      final staleTaskRealtimeChannel = _activeTaskRealtimeChannel;
      final staleSubtaskRealtimeChannel = _activeSubtaskRealtimeChannel;
      _clearActiveWatchState();
      unawaited(
        _disposeActiveWatch(
          controller: staleController,
          taskSubscription: staleTaskSubscription,
          assignmentSubscription: staleAssignmentSubscription,
          taskRealtimeChannel: staleTaskRealtimeChannel,
          subtaskRealtimeChannel: staleSubtaskRealtimeChannel,
        ),
      );
    }

    late final StreamController<List<TaskWithDetails>> controller;
    List<Map<String, dynamic>> latestTaskRows = const [];
    List<Map<String, dynamic>> latestSubtaskRows = const [];
    List<Map<String, dynamic>> latestAssignmentRows = const [];
    Set<String> watchedTaskIds = <String>{};
    StreamSubscription<List<Map<String, dynamic>>>? taskSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? assignmentSubscription;
    RealtimeChannel? subtaskRealtimeChannel;
    RealtimeChannel? taskRealtimeChannel;
    var disposed = false;
    var started = false;

    List<String> currentTaskIds() {
      return latestTaskRows
          .map((row) => row['id'])
          .whereType<String>()
          .toList(growable: false);
    }

    Future<void> refreshSubtaskCache({
      Iterable<String>? taskIdsOverride,
    }) async {
      if (disposed) {
        return;
      }

      final taskIds = (taskIdsOverride ?? currentTaskIds()).toList(
        growable: false,
      );
      if (taskIds.isEmpty) {
        latestSubtaskRows = const [];
        return;
      }

      final subtasksResponse = await supabase
          .from('subtask')
          .select('*')
          .inFilter('task_id', taskIds);

      if (disposed) {
        return;
      }

      latestSubtaskRows = List<Map<String, dynamic>>.from(
        subtasksResponse,
      ).map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    }

    Future<void> refreshAssignmentCache({
      Iterable<String>? taskIdsOverride,
    }) async {
      if (disposed) {
        return;
      }

      final taskIds = (taskIdsOverride ?? currentTaskIds()).toList(
        growable: false,
      );
      if (taskIds.isEmpty) {
        latestAssignmentRows = const [];
        return;
      }

      final assignmentsResponse = await supabase
          .from('task_assignment')
          .select('*, household_member(*, users_profile(*))')
          .inFilter('task_id', taskIds);

      if (disposed) {
        return;
      }

      latestAssignmentRows = List<Map<String, dynamic>>.from(
        assignmentsResponse,
      ).map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    }

    void emitLatestSnapshot({
      required String source,
      String? taskId,
      String? subtaskId,
    }) {
      if (disposed || controller.isClosed) {
        return;
      }

      final taskRows = latestTaskRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      if (taskRows.isEmpty) {
        if (_lastSnapshotSignature == '') {
          if (kDebugMode) {
            debugPrint('TASK SNAPSHOT SKIPPED duplicate emission');
          }
          return;
        }
        _lastSnapshotSignature = '';
        controller.add(<TaskWithDetails>[]);
        return;
      }

      final taskIds = currentTaskIds();

      if (taskIds.isEmpty) {
        if (_lastSnapshotSignature == '') {
          if (kDebugMode) {
            debugPrint('TASK SNAPSHOT SKIPPED duplicate emission');
          }
          return;
        }
        _lastSnapshotSignature = '';
        controller.add(<TaskWithDetails>[]);
        return;
      }

      final taskIdSet = taskIds.toSet();

      final subtasksByTaskId = <String, List<Map<String, dynamic>>>{};
      for (final row in latestSubtaskRows) {
        final taskId = row['task_id'] as String?;
        if (taskId == null || !taskIdSet.contains(taskId)) {
          continue;
        }

        subtasksByTaskId
            .putIfAbsent(taskId, () => <Map<String, dynamic>>[])
            .add(Map<String, dynamic>.from(row));
      }

      final assignmentsByTaskId = <String, List<Map<String, dynamic>>>{};
      for (final row in latestAssignmentRows) {
        final taskId = row['task_id'] as String?;
        if (taskId == null || !taskIdSet.contains(taskId)) {
          continue;
        }

        assignmentsByTaskId
            .putIfAbsent(taskId, () => <Map<String, dynamic>>[])
            .add(Map<String, dynamic>.from(row));
      }

      final taskDetails = taskRows
          .map((taskRow) {
            final taskId = taskRow['id'] as String?;
            final merged = Map<String, dynamic>.from(taskRow);
            merged['subtask'] = taskId == null
                ? const []
                : (subtasksByTaskId[taskId] ?? const []);
            merged['task_assignment'] = taskId == null
                ? const []
                : (assignmentsByTaskId[taskId] ?? const []);
            return TaskWithDetails.fromJson(merged);
          })
          .toList(growable: false);

      final sortedTaskDetails = taskDetails.toList(growable: false)
        ..sort((left, right) => left.task.id.compareTo(right.task.id));
      final signature = sortedTaskDetails
          .map((taskWithDetails) {
            final sortedSubtasks = taskWithDetails.subtasks.toList(
              growable: false,
            )..sort((left, right) => left.id.compareTo(right.id));
            final sortedAssignments = taskWithDetails.assignments.toList(
              growable: false,
            )..sort((left, right) => left.id.compareTo(right.id));
            final subtaskSignature = sortedSubtasks
                .map((subtask) => '${subtask.id}:${subtask.isDone ? 1 : 0}')
                .join(',');
            final assignmentSignature = sortedAssignments
                .map((assignment) => '${assignment.id}:${assignment.status}')
                .join(',');
            return '${taskWithDetails.task.id}|$subtaskSignature|$assignmentSignature';
          })
          .join('#');

      if (signature == _lastSnapshotSignature) {
        if (kDebugMode) {
          debugPrint('TASK SNAPSHOT SKIPPED duplicate emission');
        }
        return;
      }

      _lastSnapshotSignature = signature;

      if (kDebugMode) {
        debugPrint(
          'TASK REPO EMIT source=$source tasks=${taskDetails.length} scoped_task_ids=${taskIdSet.length} task_id=${taskId ?? '-'} subtask_id=${subtaskId ?? '-'}',
        );
        for (final task in taskDetails) {
          final subtaskSignature = task.subtasks
              .map((subtask) => '${subtask.id}:${subtask.isDone ? 1 : 0}')
              .join('|');
          debugPrint(
            'EMITTED TASK SNAPSHOT task_id=${task.task.id} subtasks=$subtaskSignature',
          );
        }
      }

      controller.add(taskDetails);
    }

    void handleError(Object error, StackTrace stackTrace) {
      if (disposed || controller.isClosed) {
        return;
      }

      controller.addError(error, stackTrace);
    }

    Future<void> ensureDetailSubscriptions() async {
      if (disposed) {
        return;
      }

      final nextTaskIds = currentTaskIds().toSet();
      final hasActiveSubscriptions = assignmentSubscription != null;
      if (setEquals(nextTaskIds, watchedTaskIds) && hasActiveSubscriptions) {
        return;
      }

      watchedTaskIds = nextTaskIds;

      await assignmentSubscription?.cancel();
      assignmentSubscription = null;
      _activeAssignmentSubscription = null;

      if (watchedTaskIds.isEmpty) {
        latestSubtaskRows = const [];
        latestAssignmentRows = const [];
        emitLatestSnapshot(source: 'task_scope_empty');
        return;
      }

      final scopedTaskIds = watchedTaskIds.toList(growable: false);

      assignmentSubscription = supabase
          .from('task_assignment')
          .stream(primaryKey: ['id'])
          .inFilter('task_id', scopedTaskIds)
          .listen((rows) {
            Future<void>(() async {
              latestAssignmentRows = rows
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false);
              if (scopedTaskIds.isEmpty) {
                emitLatestSnapshot(source: 'assignment_stream');
                return;
              }
              await refreshAssignmentCache(taskIdsOverride: scopedTaskIds);
              emitLatestSnapshot(source: 'assignment_stream');
            }).catchError((Object error, StackTrace stackTrace) {
              handleError(error, stackTrace);
            });
          }, onError: handleError);
      _activeAssignmentSubscription = assignmentSubscription;
    }

    Future<void> disposeCurrentWatch() async {
      if (disposed) {
        return;
      }

      disposed = true;
      if (identical(_activeWatchTasksController, controller)) {
        _clearActiveWatchState();
      }

      await _disposeActiveWatch(
        controller: controller,
        taskSubscription: taskSubscription,
        assignmentSubscription: assignmentSubscription,
        taskRealtimeChannel: taskRealtimeChannel,
        subtaskRealtimeChannel: subtaskRealtimeChannel,
      );
    }

    Future<void> startWatch() async {
      if (started || disposed) {
        return;
      }

      started = true;
      subtaskRealtimeChannel = supabase
          .channel('schema-db-changes:subtask:$householdId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'subtask',
            callback: (payload) {
              Future<void>(() async {
                if (disposed) {
                  return;
                }

                final affectedTaskId =
                    (payload.newRecord['task_id'] ??
                            payload.oldRecord['task_id'])
                        as String?;
                if (affectedTaskId == null) {
                  return;
                }

                final scopedTaskIds = currentTaskIds().toSet();
                if (!scopedTaskIds.contains(affectedTaskId)) {
                  return;
                }

                final affectedSubtaskId =
                    (payload.newRecord['id'] ?? payload.oldRecord['id'])
                        as String?;

                if (kDebugMode) {
                  debugPrint(
                    'SUBTASK REALTIME EVENT event=${payload.eventType} task_id=$affectedTaskId subtask_id=${affectedSubtaskId ?? '-'}',
                  );
                }

                await refreshSubtaskCache(taskIdsOverride: scopedTaskIds);
                emitLatestSnapshot(
                  source: 'subtask_realtime_event',
                  taskId: affectedTaskId,
                  subtaskId: affectedSubtaskId,
                );
              }).catchError((Object error, StackTrace stackTrace) {
                handleError(error, stackTrace);
              });
            },
          )
          .subscribe();
      _activeSubtaskRealtimeChannel = subtaskRealtimeChannel;

      taskRealtimeChannel = supabase
          .channel('schema-db-changes:tasks:$householdId')
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'tasks',
            callback: (payload) {
              Future<void>(() async {
                if (disposed) {
                  return;
                }

                final deletedTaskId = payload.oldRecord['id'] as String?;
                if (deletedTaskId == null) {
                  return;
                }

                final scopedTaskIds = currentTaskIds().toSet();
                if (!scopedTaskIds.contains(deletedTaskId)) {
                  return;
                }

                final freshTasks = await supabase
                    .from('tasks')
                    .select('*')
                    .eq('household_id', householdId);

                if (disposed) {
                  return;
                }

                latestTaskRows = List<Map<String, dynamic>>.from(freshTasks)
                    .map((row) => Map<String, dynamic>.from(row))
                    .toList(growable: false);

                await ensureDetailSubscriptions();
                if (watchedTaskIds.isEmpty) {
                  return;
                }
                await refreshSubtaskCache(taskIdsOverride: watchedTaskIds);
                await refreshAssignmentCache(taskIdsOverride: watchedTaskIds);

                emitLatestSnapshot(
                  source: 'task_delete_realtime_event',
                  taskId: deletedTaskId,
                );
              }).catchError((Object error, StackTrace stackTrace) {
                handleError(error, stackTrace);
              });
            },
          )
          .subscribe();
      _activeTaskRealtimeChannel = taskRealtimeChannel;

      taskSubscription = supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('household_id', householdId)
          .listen((rows) {
            Future<void>(() async {
              latestTaskRows = rows
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false);
              await ensureDetailSubscriptions();
              if (watchedTaskIds.isEmpty) {
                return;
              }
              await refreshSubtaskCache(taskIdsOverride: watchedTaskIds);
              await refreshAssignmentCache(taskIdsOverride: watchedTaskIds);
              emitLatestSnapshot(source: 'tasks_stream');
            }).catchError((Object error, StackTrace stackTrace) {
              handleError(error, stackTrace);
            });
          }, onError: handleError);
      _activeTaskSubscription = taskSubscription;
    }

    controller = StreamController<List<TaskWithDetails>>.broadcast(
      onListen: () {
        Future<void>(() async {
          await startWatch();
        }).catchError((Object error, StackTrace stackTrace) {
          handleError(error, stackTrace);
        });
      },
      onCancel: () async {
        await disposeCurrentWatch();
      },
    );

    _activeWatchTasksController = controller;
    _activeWatchTasksStream = controller.stream;
    _activeWatchHouseholdId = householdId;
    _lastSnapshotSignature = null;

    return controller.stream;
  }

  Future<void> assignTaskToMembers(
    String taskId,
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) return;

    final payload = memberIds
        .map(
          (memberId) => <String, dynamic>{
            'task_id': taskId,
            'member_id': memberId,
            'status': 'TODO',
          },
        )
        .toList();

    await supabase.from('task_assignment').insert(payload);
  }

  Future<void> createSubtasks(String taskId, List<String> titles) async {
    final sanitized = titles
        .map((title) => title.trim())
        .where((title) => title.isNotEmpty)
        .toList();

    if (sanitized.isEmpty) return;

    final payload = sanitized
        .map(
          (title) => <String, dynamic>{
            'task_id': taskId,
            'title': title,
            'is_done': false,
          },
        )
        .toList();

    await supabase.from('subtask').insert(payload);
  }

  Future<void> deleteSubtasksForTask(String taskId) async {
    await supabase.from('subtask').delete().eq('task_id', taskId);
  }

  Future<void> updateSubtaskStatus(String subtaskId, bool isDone) async {
    await supabase
        .from('subtask')
        .update({'is_done': isDone})
        .eq('id', subtaskId);
  }

  Future<bool> updateAssignmentNote({
    required String assignmentId,
    required String note,
  }) async {
    try {
      await supabase
          .from('task_assignment')
          .update({'note': note})
          .eq('id', assignmentId);
      return true;
    } catch (error) {
      debugPrint('Task note column not available yet or update failed: $error');
      return false;
    }
  }

  Future<List<TaskWithDetails>> getTasksForUserId(String userId) async {
    final response = await supabase
        .from('tasks') // The first table
        .select('*,task_assignment!inner(*), subtask(*)')
        .eq('task_assignment.member_id', userId);

    debugPrint('GETTING TASKS → userID: $userId');
    debugPrint('Response Data: $response');

    return List<Map<String, dynamic>>.from(
      response,
    ).map(TaskWithDetails.fromJson).toList();
  }

  Future<List<HouseholdRoom>> getHouseholdRooms(String householdId) async {
    try {
      final response = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name, room_type')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(
        response,
      ).map(HouseholdRoom.fromJson).toList();
    } catch (error) {
      if (!_isMissingColumnError(error, 'room_type')) {
        rethrow;
      }

      debugPrint(
        'room_type not available, loading task rooms without type: $error',
      );
      final fallbackResponse = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(fallbackResponse)
          .map((row) => HouseholdRoom.fromJson({...row, 'room_type': null}))
          .toList();
    }
  }
}
