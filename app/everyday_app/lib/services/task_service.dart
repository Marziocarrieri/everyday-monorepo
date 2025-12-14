import 'package:flutter/material.dart'; // Ci serve per TimeOfDay
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'auth_service.dart';

class TaskService {
  final TaskRepository _repo = TaskRepository();
  final AuthService _auth = AuthService();

  // creazione nuovo task
  Future<void> createTask({
    required String householdId,
    required String title,
    String? description,
    required DateTime date,
    TimeOfDay? timeFrom, // Usiamo TimeOfDay perché è facile per la UI
    TimeOfDay? timeTo,
    required String visibility, // 'ALL', 'HOST_ONLY'
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
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
      'created_by': user.id, // Firmiamo chi l'ha creato
    };

    // Mandiamo alla repository
    await _repo.createTask(taskData);
  }

  // Lettura dei dailytask
  Future<List<Task>> getTasksForDay(String householdId, DateTime date) async {
    // Chiamiamo il repository per avere i dati grezzi già trasformati in oggetti Task
    return await _repo.getTasksByDate(householdId, date);
  }
}