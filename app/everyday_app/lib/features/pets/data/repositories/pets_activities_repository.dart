import 'package:flutter/foundation.dart';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet_activity.dart'; 


class PetActivitiesRepository {
  /// Fetches all pets for a specific household ID.
  /// Maps the database response to the Pet model.
  Future<List<PetActivity>> getActivities(String petId) async {
    try {
      debugPrint('ACTIVITY LOAD → petId: $petId');

      // We query the 'pets' table (or whatever your table is named in Supabase)
      final response = await supabase
          .from('pets_activities') 
          .select('*')
          .eq('petId', petId)
          .order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED PET ACTIVITY JSON: $row');
      }

      return data
          .map((json) => PetActivity.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      rethrow; 
    }
  }

  /// Inserisce una nuova attività per un pet nella tabella 'pets_activities'
  Future<void> insertActivity({
    required String houseHoldId,
    required String petId,
    required String description,
    required DateTime date,
    required String time, // Formato "HH:mm:ss"
    String? endTime,      // Opzionale, formato "HH:mm:ss"
  }) async {
    try {
      debugPrint('SAVING ACTIVITY → petId: $petId');

      await supabase.from('pets_activities').insert({
        'houseHoldId': houseHoldId,
        'petId': petId,
        'description': description,
        'date': date.toIso8601String().split('T')[0], // Estrae solo YYYY-MM-DD
        'time': time,
        'end_time': endTime,
      });

      debugPrint('ACTIVITY SAVED SUCCESSFULLY');
    } catch (e) {
      debugPrint('Error inserting pet activity: $e');
      rethrow;
    }
  }
}