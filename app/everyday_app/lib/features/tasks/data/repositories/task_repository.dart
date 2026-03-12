import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_with_details.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import '../../../../shared/repositories/supabase_client.dart';

class TaskRepository {
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
    final controller = StreamController<List<TaskWithDetails>>();
    List<Map<String, dynamic>> latestTaskRows = const [];
    List<Map<String, dynamic>> latestSubtaskRows = const [];
    List<Map<String, dynamic>> latestAssignmentRows = const [];
    Set<String> watchedTaskIds = <String>{};
    StreamSubscription<List<Map<String, dynamic>>>? subtaskSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? assignmentSubscription;
    var disposed = false;

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
        controller.add(<TaskWithDetails>[]);
        return;
      }

      final taskIds = currentTaskIds();

      if (taskIds.isEmpty) {
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
      final hasActiveSubscriptions =
          subtaskSubscription != null && assignmentSubscription != null;
      if (setEquals(nextTaskIds, watchedTaskIds) && hasActiveSubscriptions) {
        return;
      }

      watchedTaskIds = nextTaskIds;

      await subtaskSubscription?.cancel();
      await assignmentSubscription?.cancel();
      subtaskSubscription = null;
      assignmentSubscription = null;

      if (watchedTaskIds.isEmpty) {
        latestSubtaskRows = const [];
        latestAssignmentRows = const [];
        emitLatestSnapshot(source: 'task_scope_empty');
        return;
      }

      final scopedTaskIds = watchedTaskIds.toList(growable: false);

      subtaskSubscription = supabase
          .from('subtask')
          .stream(primaryKey: ['id'])
          .inFilter('task_id', scopedTaskIds)
          .listen((rows) {
            Future<void>(() async {
              final previousSubtasksById = <String, Map<String, dynamic>>{
                for (final row in latestSubtaskRows)
                  if (row['id'] is String) row['id'] as String: row,
              };

              latestSubtaskRows = rows
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false);

              await refreshSubtaskCache(taskIdsOverride: scopedTaskIds);

              if (kDebugMode) {
                for (final row in latestSubtaskRows) {
                  final subtaskId = row['id'] as String?;
                  final taskId = row['task_id'] as String?;
                  final previousRow = subtaskId == null
                      ? null
                      : previousSubtasksById[subtaskId];
                  final didChange =
                      previousRow == null ||
                      previousRow['is_done'] != row['is_done'];

                  if (taskId == null || subtaskId == null || !didChange) {
                    continue;
                  }

                  debugPrint(
                    'SUBTASK STREAM EVENT household=$householdId task_id=$taskId subtask_id=$subtaskId is_done=${row['is_done']}',
                  );
                  emitLatestSnapshot(
                    source: 'subtask_stream',
                    taskId: taskId,
                    subtaskId: subtaskId,
                  );
                  return;
                }
              }

              emitLatestSnapshot(source: 'subtask_stream');
            }).catchError((Object error, StackTrace stackTrace) {
              handleError(error, stackTrace);
            });
          }, onError: handleError);

      assignmentSubscription = supabase
          .from('task_assignment')
          .stream(primaryKey: ['id'])
          .inFilter('task_id', scopedTaskIds)
          .listen((rows) {
            Future<void>(() async {
              latestAssignmentRows = rows
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false);
              await refreshAssignmentCache(taskIdsOverride: scopedTaskIds);
              emitLatestSnapshot(source: 'assignment_stream');
            }).catchError((Object error, StackTrace stackTrace) {
              handleError(error, stackTrace);
            });
          }, onError: handleError);
    }

    final taskSubscription = supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .listen((rows) {
          Future<void>(() async {
            latestTaskRows = rows
                .map((row) => Map<String, dynamic>.from(row))
                .toList(growable: false);
            await ensureDetailSubscriptions();
            await refreshSubtaskCache(taskIdsOverride: watchedTaskIds);
            await refreshAssignmentCache(taskIdsOverride: watchedTaskIds);
            emitLatestSnapshot(source: 'tasks_stream');
          }).catchError((Object error, StackTrace stackTrace) {
            handleError(error, stackTrace);
          });
        }, onError: handleError);

    controller.onCancel = () async {
      disposed = true;
      await taskSubscription.cancel();
      await subtaskSubscription?.cancel();
      await assignmentSubscription?.cancel();
      await controller.close();
    };

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
