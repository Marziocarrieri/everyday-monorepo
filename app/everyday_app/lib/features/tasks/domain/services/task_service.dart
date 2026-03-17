import 'package:flutter/material.dart'; // Ci serve per TimeOfDay
import '../../../../core/app_context.dart';
import '../../../../core/context_extensions.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import '../../data/models/task.dart';
import '../../data/models/task_with_details.dart';
import 'package:everyday_app/features/household/data/repositories/home_configuration_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../../../shared/services/auth_service.dart';

// --- NUOVI IMPORT PER LA SICUREZZA ---
import 'package:everyday_app/core/roles/app_role.dart';
import 'package:everyday_app/core/roles/task_visibility_policy.dart';

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
  final TaskRepository _repo;
  final AuthService _auth;
  final HouseholdRepository _householdRepository;
  final HomeConfigurationRepository _homeConfigurationRepository;

  TaskService({
    TaskRepository? taskRepository,
    AuthService? authService,
    HouseholdRepository? householdRepository,
    HomeConfigurationRepository? homeConfigurationRepository,
  }) : _repo = taskRepository ?? TaskRepository(),
       _auth = authService ?? AuthService(),
       _householdRepository = householdRepository ?? HouseholdRepository(),
       _homeConfigurationRepository =
           homeConfigurationRepository ?? HomeConfigurationRepository();

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

  Future<void> removeTaskAssignment({
    required String taskId,
    required String memberId,
  }) async {
    try {
      await _repo.removeTaskAssignment(taskId: taskId, memberId: memberId);
    } catch (error) {
      debugPrint('Error removing task assignment: $error');
      rethrow;
    }
  }

  // --- I METODI AGGIORNATI CON LA POLICY DI SICUREZZA ---
  Future<List<TaskWithDetails>> getTasksForHousehold() async {
    try {
      final householdId = requireHouseholdId();
      final activeMembership = AppContext.instance.activeMembership;
      final membershipId = AppContext.instance.membershipId;

      if (activeMembership == null || membershipId == null) return [];

      // 1. Chiediamo tutti i task della casa al repository
      final allTasks = await _repo.getTasksForHousehold(householdId);

      // 2. Determiniamo il ruolo corrente convertendolo in enum AppRole
      AppRole currentRole;
      final roleStr = activeMembership.role.toUpperCase();
      if (roleStr == 'HOST') {
        currentRole = AppRole.HOST;
      } else if (roleStr == 'COHOST') {
        currentRole = AppRole.COHOST;
      } else {
        currentRole = AppRole.PERSONNEL;
      }

      // 3. Filtriamo i task usando la TaskVisibilityPolicy (FIX APPLICATO QUI)
      final viewableTasks = allTasks.where((taskDetails) {
        // Controlliamo se l'utente corrente è assegnato a questo task
        final isAssignedToMe = taskDetails.assignments.any((a) => a.memberId == membershipId);

        // Chiediamo alla Policy se il task può essere visto
        return TaskVisibilityPolicy.canViewTask(
          userRole: currentRole,
          taskVisibility: taskDetails.task.visibility, // <- Fix: accesso corretto a visibility
          isAssignedToCurrentUser: isAssignedToMe,
        );
      }).toList();

      return viewableTasks;

    } catch (error) {
      debugPrint('Error loading household tasks: $error');
      return [];
    }
  }

  Future<List<TaskWithDetails>> getTasksAssignedToCurrentMember() async {
    final membershipId = AppContext.instance.membershipId;
    if (membershipId == null) return [];

    // Ora questo metodo chiama getTasksForHousehold() che è GIA' filtrato e sicuro!
    final tasks = await getTasksForHousehold();
    
    return tasks
        .where(
          (taskDetails) => taskDetails.assignments.any(
            (assignment) => assignment.memberId == membershipId,
          ),
        )
        .toList();
  }
  // --- FINE METODI AGGIORNATI ---

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

  // --- NUOVA FUNZIONE: COPIA UNA SETTIMANA (CON SOVRASCRITTURA) ---
  Future<void> copyWeekTasks({
    required DateTime sourceWeekDate,
    required DateTime targetWeekDate,
  }) async {
    // 1. Calcoliamo i confini della settimana sorgente
    final sourceMonday = sourceWeekDate.subtract(Duration(days: sourceWeekDate.weekday - 1));
    final sourceSunday = sourceMonday.add(const Duration(days: 6));

    // 2. Calcoliamo i confini della settimana target e la differenza di giorni (offset)
    final targetMonday = targetWeekDate.subtract(Duration(days: targetWeekDate.weekday - 1));
    final targetSunday = targetMonday.add(const Duration(days: 6));
    final offsetDays = targetMonday.difference(sourceMonday).inDays;

    if (offsetDays == 0) return; // Non ha senso copiare la stessa settimana su se stessa

    // 3. Peschiamo tutti i task
    final allTasks = await getTasksForHousehold();

    // 4. Teniamo solo quelli della settimana sorgente
    final sourceTasks = allTasks.where((t) {
      final taskDate = DateTime(t.task.taskDate.year, t.task.taskDate.month, t.task.taskDate.day);
      final s = DateTime(sourceMonday.year, sourceMonday.month, sourceMonday.day);
      final e = DateTime(sourceSunday.year, sourceSunday.month, sourceSunday.day);
      return taskDate.isAfter(s.subtract(const Duration(days: 1))) && 
             taskDate.isBefore(e.add(const Duration(days: 1)));
    }).toList();

    // Controlliamo PRIMA di cancellare qualsiasi cosa che ci siano effettivamente task da copiare
    if (sourceTasks.isEmpty) throw Exception("No tasks found in the selected source week.");

    // 5. Troviamo i task della settimana target per ELIMINARLI (Sovrascrittura)
    final targetTasksToDelete = allTasks.where((t) {
      final taskDate = DateTime(t.task.taskDate.year, t.task.taskDate.month, t.task.taskDate.day);
      final s = DateTime(targetMonday.year, targetMonday.month, targetMonday.day);
      final e = DateTime(targetSunday.year, targetSunday.month, targetSunday.day);
      return taskDate.isAfter(s.subtract(const Duration(days: 1))) && 
             taskDate.isBefore(e.add(const Duration(days: 1)));
    }).toList();

    // Cancelliamo i task esistenti nella settimana di destinazione
    for (final t in targetTasksToDelete) {
      await deleteTask(t.task.id);
    }

    // Helper per riconvertire la stringa dell'orario in TimeOfDay
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    }

    // 6. Creiamo i cloni
    for (final t in sourceTasks) {
      final newDate = t.task.taskDate.add(Duration(days: offsetDays));
      final checklistTitles = t.subtasks.map((st) => st.title).toList();
      final assignedMemberIds = t.assignments.map((a) => a.memberId).toList();

      await createTaskWithDetails(
        title: t.task.title,
        description: t.task.description,
        date: newDate,
        timeFrom: parseTime(t.task.timeFrom),
        timeTo: parseTime(t.task.timeTo),
        visibility: t.task.visibility,
        roomId: t.task.roomId,
        assignedMemberIds: assignedMemberIds,
        checklistTitles: checklistTitles,
        personalOnly: false,
      );
    }
  }

  // --- NUOVA FUNZIONE: COPIA UN SINGOLO GIORNO CON SOVRASCRITTURA ---
  Future<void> copyDayTasks({
    required DateTime sourceDate,
    required DateTime targetDate,
  }) async {
    // 1. Peschiamo tutti i task
    final allTasks = await getTasksForHousehold();

    // 2. Identifichiamo i task del giorno sorgente e quelli del giorno target
    final sourceTasks = allTasks.where((t) => 
      t.task.taskDate.year == sourceDate.year && 
      t.task.taskDate.month == sourceDate.month && 
      t.task.taskDate.day == sourceDate.day
    ).toList();

    final targetTasks = allTasks.where((t) => 
      t.task.taskDate.year == targetDate.year && 
      t.task.taskDate.month == targetDate.month && 
      t.task.taskDate.day == targetDate.day
    ).toList();

    // 3. ELIMINIAMO i task esistenti nel giorno target (Sovrascrittura)
    for (final t in targetTasks) {
      await deleteTask(t.task.id);
    }

    if (sourceTasks.isEmpty) return;

    // Helper orario
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    }

    // 4. CLONIAMO i task sorgente nel giorno target
    for (final t in sourceTasks) {
      final checklistTitles = t.subtasks.map((st) => st.title).toList();
      final assignedMemberIds = t.assignments.map((a) => a.memberId).toList();

      await createTaskWithDetails(
        title: t.task.title,
        description: t.task.description,
        date: targetDate, // Usiamo la data di oggi/target
        timeFrom: parseTime(t.task.timeFrom),
        timeTo: parseTime(t.task.timeTo),
        visibility: t.task.visibility,
        roomId: t.task.roomId,
        assignedMemberIds: assignedMemberIds,
        checklistTitles: checklistTitles,
        personalOnly: false,
      );
    }
  }
}