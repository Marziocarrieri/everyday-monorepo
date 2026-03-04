import 'package:flutter/material.dart'; // Ci serve per TimeOfDay
import '../core/app_context.dart';
import '../core/context_extensions.dart';
import '../models/household_member.dart';
import '../models/household_room.dart';
import '../models/task.dart';
import '../models/task_with_details.dart';
import '../repositories/home_configuration_repository.dart';
import '../repositories/household_repository.dart';
import '../repositories/task_repository.dart';
import 'auth_service.dart';

class TaskCreationAccess {
  final bool canCreate;
  final bool canAssignMultiple;
  final List<HouseholdMember> assignableMembers;

  const TaskCreationAccess({
    required this.canCreate,
    required this.canAssignMultiple,
    required this.assignableMembers,
  });
}

class TaskService {
  final TaskRepository _repo = TaskRepository();
  final AuthService _auth = AuthService();
  final HouseholdRepository _householdRepository = HouseholdRepository();
  final HomeConfigurationRepository _homeConfigurationRepository =
      HomeConfigurationRepository();

  // creazione nuovo task
  Future<void> createTask({
    required String title,
    String? description,
    required DateTime date,
    TimeOfDay? timeFrom, // Usiamo TimeOfDay perché è facile per la UI
    TimeOfDay? timeTo,
    required String visibility, // 'ALL', 'HOST_ONLY'
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final householdId = requireHouseholdId();
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) {
      throw Exception('Membership context not initialized');
    }
    
    // Converto l'orario in testo
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      // .padLeft(2, '0') assicura che 9 diventi "09"
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    final Map<String, dynamic> taskData = {
      'household_id': householdId,
      'title': title,
      'description': description,
      'task_date': date.toIso8601String(), // Convertiamo la data in testo ISO
      'time_from': formatTime(timeFrom),
      'time_to': formatTime(timeTo),
      'visibility': visibility,
      'created_by': membershipId,
    };

    // Mandiamo alla repository
    await _repo.createTask(taskData);
  }

  // Lettura dei dailytask
  Future<List<Task>> getTasksForDay(DateTime date) async {
    final householdId = requireHouseholdId();

    // Chiamiamo il repository per avere i dati grezzi già trasformati in oggetti Task
    return await _repo.getTasksByDate(householdId, date);
  }

  Future<List<HouseholdRoom>> getAvailableRooms() async {
    try {
      final householdId = requireHouseholdId();
      return await _homeConfigurationRepository.getRoomsForHousehold(
        householdId,
      );
    } catch (error) {
      debugPrint('Error loading rooms for task creation: $error');
      return [];
    }
  }

  Future<TaskCreationAccess> getTaskCreationAccess() async {
    final activeMembership = AppContext.instance.activeMembership;
    final membershipId = AppContext.instance.membershipId;
    final householdId = AppContext.instance.householdId;

    if (activeMembership == null || membershipId == null || householdId == null) {
      return const TaskCreationAccess(
        canCreate: false,
        canAssignMultiple: false,
        assignableMembers: [],
      );
    }

    final role = activeMembership.role.toUpperCase();
    if (role == 'PERSONNEL') {
      return const TaskCreationAccess(
        canCreate: false,
        canAssignMultiple: false,
        assignableMembers: [],
      );
    }

    try {
      final members = await _householdRepository.getMembers(householdId);
      if (role == 'HOST') {
        return TaskCreationAccess(
          canCreate: true,
          canAssignMultiple: true,
          assignableMembers: members,
        );
      }

      final selfOnly = members
          .where((member) => member.id == membershipId)
          .toList();

      return TaskCreationAccess(
        canCreate: true,
        canAssignMultiple: false,
        assignableMembers: selfOnly,
      );
    } catch (error) {
      debugPrint('Error loading task creation access: $error');
      return const TaskCreationAccess(
        canCreate: false,
        canAssignMultiple: false,
        assignableMembers: [],
      );
    }
  }

  Future<void> createTaskWithDetails({
    required String title,
    String? description,
    required DateTime date,
    TimeOfDay? timeFrom,
    TimeOfDay? timeTo,
    String visibility = 'ALL',
    String? roomId,
    required List<String> assignedMemberIds,
    required List<String> checklistTitles,
    bool personalOnly = false,
  }) async {
    final user = _auth.currentUser;
    final householdId = AppContext.instance.householdId;
    final membershipId = AppContext.instance.membershipId;
    final activeMembership = AppContext.instance.activeMembership;

    if (user == null || householdId == null || membershipId == null || activeMembership == null) {
      throw Exception('Missing session context');
    }

    final role = activeMembership.role.toUpperCase();
    if (role == 'PERSONNEL') {
      throw Exception('Personnel members cannot create tasks');
    }

    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    final taskData = <String, dynamic>{
      'household_id': householdId,
      'title': title,
      'description': description,
      'task_date': date.toIso8601String(),
      'time_from': formatTime(timeFrom),
      'time_to': formatTime(timeTo),
      'visibility': visibility,
      'created_by': membershipId,
    };

    if (roomId != null && roomId.isNotEmpty) {
      taskData['room_id'] = roomId;
    }

    final effectiveAssignments = personalOnly
      ? <String>[membershipId]
      : role == 'HOST'
        ? assignedMemberIds
        : <String>[membershipId];

    final taskId = await _repo.createTask(taskData);
    await _repo.assignTaskToMembers(taskId, effectiveAssignments);
    await _repo.createSubtasks(taskId, checklistTitles);
  }

  Future<void> updateTaskWithDetails({
    required String taskId,
    required String title,
    String? description,
    required DateTime date,
    TimeOfDay? timeFrom,
    TimeOfDay? timeTo,
    String visibility = 'ALL',
    String? roomId,
    required List<String> checklistTitles,
  }) async {
    final householdId = AppContext.instance.householdId;
    final membershipId = AppContext.instance.membershipId;
    if (householdId == null || membershipId == null) {
      throw Exception('Missing session context');
    }

    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    final taskData = <String, dynamic>{
      'household_id': householdId,
      'title': title,
      'description': description,
      'task_date': date.toIso8601String(),
      'time_from': formatTime(timeFrom),
      'time_to': formatTime(timeTo),
      'visibility': visibility,
      'created_by': membershipId,
      'room_id': roomId,
    };

    await _repo.updateTask(taskId, taskData);
    await _repo.deleteSubtasksForTask(taskId);
    await _repo.createSubtasks(taskId, checklistTitles);
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
    } catch (error) {
      debugPrint('Error deleting task: $error');
      rethrow;
    }
  }

  Future<List<TaskWithDetails>> getTasksForHousehold() async {
    try {
      final householdId = requireHouseholdId();
      return await _repo.getTasksForHousehold(householdId);
    } catch (error) {
      debugPrint('Error loading household tasks: $error');
      return [];
    }
  }

  Future<List<TaskWithDetails>> getTasksAssignedToCurrentMember() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) return [];

    final tasks = await getTasksForHousehold();
    return tasks
        .where(
          (task) => task.assignments.any(
            (assignment) => assignment.memberId == membershipId,
          ),
        )
        .toList();
  }

  Future<void> setSubtaskDone({
    required String subtaskId,
    required bool isDone,
  }) async {
    try {
      await _repo.updateSubtaskStatus(subtaskId, isDone);
    } catch (error) {
      debugPrint('Error updating subtask status: $error');
      rethrow;
    }
  }

  Future<void> setAssignmentStatus({
    required String assignmentId,
    required String status,
  }) async {
    try {
      await _repo.updateAssignmentStatus(assignmentId, status);
    } catch (error) {
      debugPrint('Error updating assignment status: $error');
      rethrow;
    }
  }

  Future<bool> addPersonnelNote({
    required String assignmentId,
    required String note,
  }) async {
    try {
      return await _repo.updateAssignmentNote(
        assignmentId: assignmentId,
        note: note,
      );
    } catch (error) {
      debugPrint('Error saving personnel note: $error');
      return false;
    }
  }
}