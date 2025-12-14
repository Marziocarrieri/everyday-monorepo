import '../models/task.dart';
import 'supabase_client.dart';

class TaskRepository {

  // 1. SALVA UN TASK
  Future<String> createTask(Map<String, dynamic> taskData) async {
    // taskData è già una mappa pronta preparata dal Service
    final res = await supabase
        .from('tasks')
        .insert(taskData)
        .select('id') // Ci serve solo l'ID indietro
        .single();
    
    return res['id'];
  }

  // 2. SCARICA I TASK DI UN GIORNO
  Future<List<Task>> getTasksByDate(String householdId, DateTime date) async {
    // Convertiamo la data in stringa "2025-12-13" perché il DB capisce solo testo
    final dateString = date.toIso8601String().split('T')[0];

    final response = await supabase
        .from('tasks')
        .select() // Prendi tutto
        .eq('household_id', householdId) // Filtra per casa
        .eq('task_date', dateString)     // Filtra per data esatta
        .order('created_at');            // Mettili in ordine cronologico

    // Trasformiamo la lista di dati grezzi in una lista di oggetti Task
    return (response as List).map((json) => Task.fromJson(json)).toList();
  }
  
  // 3. ASSEGNA TASK
  Future<void> assignTask(String taskId, String memberId) async {
    await supabase.from('task_assignment').insert({
      'task_id': taskId,
      'member_id': memberId,
      'status': 'TODO'
    });
  }
}