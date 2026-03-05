import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subtask.dart';

class SubtaskService {
  final _supabase = Supabase.instance.client;

  // Carica i subtask di un task specifico
  Future<List<Subtask>> getSubtasks(String taskId) async {
    final response = await _supabase
        .from('subtask')
        .select()
        .eq('task_id', taskId)
        .order('id'); // Ordine di creazione

    return (response as List).map((json) => Subtask.fromJson(json)).toList();
  }

  // Spunta un subtask (Fatto/Non fatto)
  Future<void> toggleSubtask(String subtaskId, bool isDone) async {
    await _supabase
        .from('subtask')
        .update({'is_done': isDone})
        .eq('id', subtaskId);
  }
}