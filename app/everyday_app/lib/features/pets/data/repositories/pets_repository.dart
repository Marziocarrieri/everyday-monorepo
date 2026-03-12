import 'package:flutter/foundation.dart';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet.dart'; 

class PetRepository {
  /// Fetches all pets for a specific household ID.
  /// Maps the database response to the Pet model.
  Future<List<Pet>> getPets(String householdId) async {
    try {
      debugPrint('PETS LOAD → household: $householdId');

      // We query the 'pets' table
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

  /// Crea un nuovo Pet
  Future<void> createPet({
    required String name,
    required String species,
    required String householdId,
  }) async {
    try {
      await supabase.from('pets').insert({
        'name': name,
        'species': species,
        'household_id': householdId,
      });
      debugPrint('PET CREATED: $name');
    } catch (e) {
      debugPrint('Error creating pet: $e');
      rethrow;
    }
  }

  /// Elimina un Pet specifico dal database usando il suo ID
  Future<void> deletePet(String petId) async {
    try {
      debugPrint('DELETING PET → id: $petId');

      await supabase
          .from('pets')
          .delete()
          .eq('id', petId);

      debugPrint('PET DELETED SUCCESSFULLY');
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      rethrow;
    }
  }
}