import 'package:flutter/foundation.dart';
import 'supabase_client.dart';
import '../models/pet.dart'; 


class PetRepository {
  /// Fetches all pets for a specific household ID.
  /// Maps the database response to the Pet model.
  Future<List<Pet>> getPets(String householdId) async {
    try {
      debugPrint('PETS LOAD → household: $householdId');

      // We query the 'pets' table (or whatever your table is named in Supabase)
      final response = await supabase
          .from('pets') 
          .select('*')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED PET JSON: $row');
      }

      return data
          .map((json) => Pet.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      rethrow; 
    }
  }
}