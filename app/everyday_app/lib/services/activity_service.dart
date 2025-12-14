import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  // Chiamata diretta
  final _supabase = Supabase.instance.client;

  // Giorni "occupati" in un certo mese
  // Restituisce una lista di date 
  Future<List<DateTime>> getDaysWithTasks(String householdId, DateTime start, DateTime end) async {
    try {
      // chiamata leggera
      final response = await _supabase
          .from('task')
          .select('task_date') 
          .eq('household_id', householdId)
          .gte('task_date', start.toIso8601String()) // gte = Greater Than or Equal (Da questa data...)
          .lte('task_date', end.toIso8601String());  // lte = Less Than or Equal (...a questa data)

      // Pulizia dei dati
      final Set<String> uniqueDates = {}; // 'Set' è una lista che rifiuta i duplicati 
      
      for (var row in response) {
        String rawDate = row['task_date']; 
        uniqueDates.add(rawDate.split('T')[0]); 
      }

      // Trasformiamo le stringhe pulite di nuovo in oggetti DateTime veri e propri
      return uniqueDates.map((dateString) => DateTime.parse(dateString)).toList();

    } catch (e) {
      return [];
    }
  }
}