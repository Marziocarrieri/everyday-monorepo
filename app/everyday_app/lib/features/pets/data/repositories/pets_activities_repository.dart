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
}