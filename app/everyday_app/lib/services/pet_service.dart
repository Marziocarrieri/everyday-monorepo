import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart'; // Importiamo lo stampino dell'Animale

class PetService {
  // Siccome non abbiamo un PetRepository, usiamo direttamente il client di Supabase qui.
  final _supabase = Supabase.instance.client;

  // Lista degli animali
  Future<List<Pet>> getPets(String householdId) async {
    try {
      final response = await _supabase
          .from('pets') // Tabella 'pets'
          .select()
          .eq('household_id', householdId) // Filtro per casa
          .order('name'); // Ordine alfabetico

      // Trasformiamo i dati grezzi (JSON) in oggetti Pet usando lo stampino
      return (response as List).map((json) => Pet.fromJson(json)).toList();
      
    } catch (e) {
      return [];
    }
  }

  // Aggiungere un pet
  Future<void> addPet({
    required String householdId,
    required String name,
    // String? species, 
    // String? breed,   // "Labrador" (opzionale)
    // DateTime? birthdate,
  }) async {
    
    await _supabase.from('pets').insert({
      'household_id': householdId,
      'name': name,
      // 'species': species,
      // 'breed': breed,
      // 'birthdate': birthdate?.toIso8601String(), // Trasformiamo la data in testo per il DB
    });
  }

  // Rimuovere un pet
  Future<void> deletePet(String petId) async {
    await _supabase.from('pets').delete().eq('id', petId);
  }
}