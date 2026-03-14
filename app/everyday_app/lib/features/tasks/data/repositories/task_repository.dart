import 'dart:async';
import 'dart:convert';

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
  RealtimeChannel? _activeAssignmentRealtimeChannel;
  String? _activeWatchHouseholdId;
  String? _lastSnapshotSignature;

  void _clearActiveWatchState() {
    _activeWatchTasksController = null;
    _activeWatchTasksStream = null;
    _activeTaskSubscription = null;
    _activeAssignmentSubscription = null;
    _activeSubtaskRealtimeChannel = null;
    _activeTaskRealtimeChannel = null;
    _activeAssignmentRealtimeChannel = null;
    _activeWatchHouseholdId = null;
    _lastSnapshotSignature = null;
  }

  Future<void> _disposeActiveWatch({
    StreamController<List<TaskWithDetails>>? controller,
    StreamSubscription<List<Map<String, dynamic>>>? taskSubscription,
    StreamSubscription<List<Map<String, dynamic>>>? assignmentSubscription,
    RealtimeChannel? taskRealtimeChannel,
    RealtimeChannel? subtaskRealtimeChannel,
    RealtimeChannel? assignmentRealtimeChannel,
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
    if (assignmentRealtimeChannel != null) {
      await supabase.removeChannel(assignmentRealtimeChannel);
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

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  TaskWithDetails? _tryParseTaskWithDetails(
    Map<String, dynamic> row, {
    required String source,
  }) {
    final taskId = _readString(row['id']) ?? _readString(row['task_id']) ?? '-';

    try {
      return TaskWithDetails.fromJson(row);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'TASK_REPO_SKIP_MALFORMED_ROW source=$source task_id=$taskId error=$error',
        );
      }
      return null;
    }
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
    final tasks = <Task>[];
    for (final row in List<dynamic>.from(response)) {
      if (row is! Map) {
        continue;
      }

      final rowMap = Map<String, dynamic>.from(row);
      try {
        tasks.add(Task.fromJson(rowMap));
      } catch (error) {
        if (kDebugMode) {
          final taskId = _readString(rowMap['id']) ?? '-';
          debugPrint(
            'TASK_REPO_SKIP_MALFORMED_ROW source=get_tasks_by_date task_id=$taskId error=$error',
          );
        }
      }
    }

    return tasks;
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

    final taskRows = List<Map<String, dynamic>>.from(
      response,
    ).map((row) => Map<String, dynamic>.from(row));

    final parsed = <TaskWithDetails>[];
    for (final row in taskRows) {
      final mapped = _tryParseTaskWithDetails(
        row,
        source: 'get_tasks_for_household',
      );
      if (mapped == null) {
        continue;
      }
      parsed.add(mapped);
    }

    return parsed;
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
      final staleAssignmentRealtimeChannel = _activeAssignmentRealtimeChannel;
      _clearActiveWatchState();
      unawaited(
        _disposeActiveWatch(
          controller: staleController,
          taskSubscription: staleTaskSubscription,
          assignmentSubscription: staleAssignmentSubscription,
          taskRealtimeChannel: staleTaskRealtimeChannel,
          subtaskRealtimeChannel: staleSubtaskRealtimeChannel,
          assignmentRealtimeChannel: staleAssignmentRealtimeChannel,
        ),
      );
    }

    late final StreamController<List<TaskWithDetails>> controller;
    final watchInstanceId = DateTime.now().microsecondsSinceEpoch.toString();
    List<Map<String, dynamic>> latestTaskRows = const [];
    List<Map<String, dynamic>> latestSubtaskRows = const [];
    List<Map<String, dynamic>> latestAssignmentRows = const [];
    Set<String> watchedTaskIds = <String>{};
    StreamSubscription<List<Map<String, dynamic>>>? taskSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? assignmentSubscription;
    RealtimeChannel? subtaskRealtimeChannel;
    RealtimeChannel? taskRealtimeChannel;
    RealtimeChannel? assignmentRealtimeChannel;
    var disposed = false;
    var started = false;
    var lifecycleVersion = 0;

    void logWatchEvent(
      String event, {
      Map<String, Object?> details = const {},
    }) {
      if (!kDebugMode) {
        return;
      }

      final payload = <String, Object?>{
        'event': event,
        'watch_id': watchInstanceId,
        'household_id': householdId,
        'lifecycle_version': lifecycleVersion,
        'disposed': disposed,
        'started': started,
        'has_listener': controller.hasListener,
        'tasks_cached': latestTaskRows.length,
        'assignments_cached': latestAssignmentRows.length,
        'subtasks_cached': latestSubtaskRows.length,
        'watched_task_ids': watchedTaskIds.length,
      };
      payload.addAll(details);

      debugPrint('TASK_WATCH ${jsonEncode(payload)}');
    }

    List<String> currentTaskIds() {
      return latestTaskRows
          .map((row) => _readString(row['id']))
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
        logWatchEvent(
          'emit_skipped_closed_or_disposed',
          details: <String, Object?>{
            'source': source,
            'reason': disposed ? 'disposed' : 'controller_closed',
          },
        );
        return;
      }

      final taskRows = latestTaskRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      if (taskRows.isEmpty) {
        if (_lastSnapshotSignature == '') {
          logWatchEvent(
            'emit_skipped_duplicate_signature',
            details: <String, Object?>{
              'source': source,
              'reason': 'empty_signature_duplicate',
              'signature': '',
              'is_empty_snapshot': true,
            },
          );
          return;
        }

        logWatchEvent(
          'emit_snapshot',
          details: <String, Object?>{
            'source': source,
            'signature': '',
            'is_empty_snapshot': true,
            'tasks_received': 0,
            'assignments_received': latestAssignmentRows.length,
          },
        );
        _lastSnapshotSignature = '';
        controller.add(<TaskWithDetails>[]);
        return;
      }

      final taskIds = currentTaskIds();

      if (taskIds.isEmpty) {
        if (_lastSnapshotSignature == '') {
          logWatchEvent(
            'emit_skipped_duplicate_signature',
            details: <String, Object?>{
              'source': source,
              'reason': 'task_ids_empty_signature_duplicate',
              'signature': '',
              'is_empty_snapshot': true,
            },
          );
          return;
        }

        logWatchEvent(
          'emit_snapshot',
          details: <String, Object?>{
            'source': source,
            'signature': '',
            'is_empty_snapshot': true,
            'tasks_received': taskRows.length,
            'assignments_received': latestAssignmentRows.length,
          },
        );
        _lastSnapshotSignature = '';
        controller.add(<TaskWithDetails>[]);
        return;
      }

      final taskIdSet = taskIds.toSet();

      final subtasksByTaskId = <String, List<Map<String, dynamic>>>{};
      for (final row in latestSubtaskRows) {
        final subtaskTaskId = _readString(row['task_id']);
        if (subtaskTaskId == null || !taskIdSet.contains(subtaskTaskId)) {
          continue;
        }

        subtasksByTaskId
            .putIfAbsent(subtaskTaskId, () => <Map<String, dynamic>>[])
            .add(Map<String, dynamic>.from(row));
      }

      final assignmentsByTaskId = <String, List<Map<String, dynamic>>>{};
      for (final row in latestAssignmentRows) {
        final assignmentTaskId = _readString(row['task_id']);
        if (assignmentTaskId == null || !taskIdSet.contains(assignmentTaskId)) {
          continue;
        }

        assignmentsByTaskId
            .putIfAbsent(assignmentTaskId, () => <Map<String, dynamic>>[])
            .add(Map<String, dynamic>.from(row));
      }

      final taskDetails = <TaskWithDetails>[];
      for (final taskRow in taskRows) {
        final rowTaskId = _readString(taskRow['id']);
        final merged = Map<String, dynamic>.from(taskRow);
        merged['subtask'] = rowTaskId == null
            ? const <Map<String, dynamic>>[]
            : (subtasksByTaskId[rowTaskId] ?? const <Map<String, dynamic>>[]);
        merged['task_assignment'] = rowTaskId == null
            ? const <Map<String, dynamic>>[]
            : (assignmentsByTaskId[rowTaskId] ?? const <Map<String, dynamic>>[]);

        final parsed = _tryParseTaskWithDetails(
          merged,
          source: 'watch_emit',
        );
        if (parsed == null) {
          continue;
        }

        taskDetails.add(parsed);
      }

      final sortedTaskDetails = taskDetails.toList(growable: false)
        ..sort((left, right) => left.task.id.compareTo(right.task.id));
      final signature = sortedTaskDetails
          .map((taskWithDetails) {
            final task = taskWithDetails.task;
            final taskCoreSig =
                '${task.id}'
                '|${task.title}'
                '|${task.taskDate.toIso8601String()}'
                '|${task.timeFrom ?? '-'}'
                '|${task.timeTo ?? '-'}'
                '|${task.description ?? '-'}'
                '|${task.roomId ?? '-'}'
                '|${task.repeatRule}'
                '|${task.visibility}'
                '|${task.createdBy ?? '-'}';
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
                .map(
                  (assignment) =>
                      '${assignment.id}:${assignment.status}:${assignment.note ?? '-'}',
                )
                .join(',');
            return '$taskCoreSig|$subtaskSignature|$assignmentSignature';
          })
          .join('#');

      if (signature == _lastSnapshotSignature) {
        logWatchEvent(
          'emit_skipped_duplicate_signature',
          details: <String, Object?>{
            'source': source,
            'reason': 'signature_duplicate',
            'signature': signature,
            'is_empty_snapshot': false,
            'tasks_received': taskRows.length,
            'assignments_received': latestAssignmentRows.length,
          },
        );
        return;
      }

      _lastSnapshotSignature = signature;

      logWatchEvent(
        'emit_snapshot',
        details: <String, Object?>{
          'source': source,
          'signature': signature,
          'is_empty_snapshot': taskDetails.isEmpty,
          'tasks_received': taskRows.length,
          'assignments_received': latestAssignmentRows.length,
          'task_id': taskId,
          'subtask_id': subtaskId,
        },
      );

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
        logWatchEvent(
          'error_ignored_closed_or_disposed',
          details: <String, Object?>{
            'error': error.toString(),
          },
        );
        return;
      }

      logWatchEvent(
        'error_forwarded',
        details: <String, Object?>{
          'error': error.toString(),
        },
      );

      controller.addError(error, stackTrace);
    }

    Future<void> ensureDetailSubscriptions() async {
      if (disposed) {
        return;
      }

      final nextTaskIds = currentTaskIds().toSet();
      final hasActiveSubscriptions = assignmentSubscription != null;
      if (setEquals(nextTaskIds, watchedTaskIds) && hasActiveSubscriptions) {
        logWatchEvent(
          'assignment_scope_unchanged',
          details: <String, Object?>{
            'task_ids': nextTaskIds.length,
          },
        );
        return;
      }

      watchedTaskIds = nextTaskIds;

      logWatchEvent(
        'assignment_scope_updated',
        details: <String, Object?>{
          'task_ids': watchedTaskIds.length,
        },
      );

      await assignmentSubscription?.cancel();
      assignmentSubscription = null;
      _activeAssignmentSubscription = null;

      if (watchedTaskIds.isEmpty) {
        latestSubtaskRows = const [];
        latestAssignmentRows = const [];
        logWatchEvent(
          'assignment_scope_empty',
          details: <String, Object?>{
            'reason': 'no_task_ids',
          },
        );
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
              logWatchEvent(
                'assignment_stream_rows_received',
                details: <String, Object?>{
                  'rows': rows.length,
                },
              );

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
      logWatchEvent('dispose_watch_start');
      if (identical(_activeWatchTasksController, controller)) {
        _clearActiveWatchState();
      }

      await _disposeActiveWatch(
        controller: controller,
        taskSubscription: taskSubscription,
        assignmentSubscription: assignmentSubscription,
        taskRealtimeChannel: taskRealtimeChannel,
        subtaskRealtimeChannel: subtaskRealtimeChannel,
        assignmentRealtimeChannel: assignmentRealtimeChannel,
      );

      logWatchEvent('dispose_watch_complete');
    }

    Future<void> scheduleDisposeCurrentWatch() async {
      final expectedVersion = ++lifecycleVersion;
      logWatchEvent(
        'dispose_watch_scheduled',
        details: <String, Object?>{
          'expected_version': expectedVersion,
        },
      );
      await Future<void>.microtask(() {});

      if (disposed || controller.isClosed) {
        logWatchEvent(
          'dispose_watch_skipped',
          details: <String, Object?>{
            'reason': disposed ? 'already_disposed' : 'controller_closed',
            'expected_version': expectedVersion,
          },
        );
        return;
      }

      if (expectedVersion != lifecycleVersion) {
        logWatchEvent(
          'dispose_watch_skipped',
          details: <String, Object?>{
            'reason': 'lifecycle_version_changed',
            'expected_version': expectedVersion,
            'actual_version': lifecycleVersion,
          },
        );
        return;
      }

      if (controller.hasListener) {
        logWatchEvent(
          'dispose_watch_skipped',
          details: <String, Object?>{
            'reason': 'listener_recovered',
            'expected_version': expectedVersion,
          },
        );
        return;
      }

      await disposeCurrentWatch();
    }

    Future<void> startWatch() async {
      if (started || disposed) {
        logWatchEvent(
          'start_watch_skipped',
          details: <String, Object?>{
            'reason': started ? 'already_started' : 'disposed',
          },
        );
        return;
      }

      started = true;
      logWatchEvent('start_watch');
      subtaskRealtimeChannel = supabase
          .channel('schema-db-changes:subtask:$householdId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'subtask',
            callback: (payload) {
              Future<void>(() async {
                logWatchEvent(
                  'subtask_realtime_payload',
                  details: <String, Object?>{
                    'event_type': payload.eventType.name,
                  },
                );

                if (disposed) {
                  return;
                }

                final affectedTaskId =
                    _readString(
                      payload.newRecord['task_id'] ??
                          payload.oldRecord['task_id'],
                    );
                if (affectedTaskId == null) {
                  return;
                }

                final scopedTaskIds = currentTaskIds().toSet();
                if (!scopedTaskIds.contains(affectedTaskId)) {
                  return;
                }

                final affectedSubtaskId =
                  _readString(payload.newRecord['id'] ?? payload.oldRecord['id']);

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
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            callback: (payload) {
              Future<void>(() async {
                logWatchEvent(
                  'tasks_realtime_payload',
                  details: <String, Object?>{
                    'event_type': payload.eventType.name,
                  },
                );

                if (disposed) {
                  return;
                }

                if (payload.eventType != PostgresChangeEvent.delete) {
                  return;
                }

                final deletedTaskId = _readString(payload.oldRecord['id']);
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

      assignmentRealtimeChannel = supabase
          .channel('schema-db-changes:task-assignment:$householdId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'task_assignment',
            callback: (payload) {
              Future<void>(() async {
                logWatchEvent(
                  'assignment_realtime_payload',
                  details: <String, Object?>{
                    'event_type': payload.eventType.name,
                  },
                );

                if (disposed) {
                  return;
                }

                final affectedTaskId =
                    _readString(
                      payload.newRecord['task_id'] ??
                          payload.oldRecord['task_id'],
                    );
                if (affectedTaskId == null) {
                  return;
                }

                final scopedTaskIds = currentTaskIds().toSet();
                if (!scopedTaskIds.contains(affectedTaskId)) {
                  return;
                }

                await refreshAssignmentCache(taskIdsOverride: scopedTaskIds);
                emitLatestSnapshot(
                  source: 'assignment_realtime_event',
                  taskId: affectedTaskId,
                );
              }).catchError((Object error, StackTrace stackTrace) {
                handleError(error, stackTrace);
              });
            },
          )
          .subscribe();
      _activeAssignmentRealtimeChannel = assignmentRealtimeChannel;

      taskSubscription = supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('household_id', householdId)
          .listen((rows) {
            Future<void>(() async {
              logWatchEvent(
                'tasks_stream_rows_received',
                details: <String, Object?>{
                  'rows': rows.length,
                },
              );

              latestTaskRows = rows
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false);

              if (latestTaskRows.isEmpty) {
                final freshTasks = await supabase
                    .from('tasks')
                    .select('*')
                    .eq('household_id', householdId);

                if (disposed) {
                  return;
                }

                final refreshedRows = List<Map<String, dynamic>>.from(
                  freshTasks,
                ).map((row) => Map<String, dynamic>.from(row)).toList(
                  growable: false,
                );

                if (refreshedRows.isNotEmpty) {
                  logWatchEvent(
                    'tasks_stream_empty_suppressed',
                    details: <String, Object?>{
                      'refreshed_rows': refreshedRows.length,
                    },
                  );
                  latestTaskRows = refreshedRows;
                } else {
                  logWatchEvent('tasks_stream_empty_confirmed');
                }
              }

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
        lifecycleVersion++;
        logWatchEvent(
          'controller_on_listen',
          details: <String, Object?>{
            'lifecycle_version_after_increment': lifecycleVersion,
          },
        );
        Future<void>(() async {
          await startWatch();
        }).catchError((Object error, StackTrace stackTrace) {
          handleError(error, stackTrace);
        });
      },
      onCancel: () async {
        logWatchEvent('controller_on_cancel');
        await scheduleDisposeCurrentWatch();
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

    final taskRows = List<Map<String, dynamic>>.from(
      response,
    ).map((row) => Map<String, dynamic>.from(row));

    final parsed = <TaskWithDetails>[];
    for (final row in taskRows) {
      final mapped = _tryParseTaskWithDetails(
        row,
        source: 'get_tasks_for_user',
      );
      if (mapped == null) {
        continue;
      }
      parsed.add(mapped);
    }

    return parsed;
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
