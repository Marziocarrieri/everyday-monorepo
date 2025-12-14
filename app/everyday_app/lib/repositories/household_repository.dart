import '../models/household.dart';
import 'supabase_client.dart';
import 'package:flutter/foundation.dart';

class HouseholdRepository {

  // 1. CREA UNA NUOVA CASA
  // Restituisce una Stringa (l'ID della casa creata)
  Future<String> createHousehold(String name, String address) async {
    // .insert(...) -> Inserisce una nuova riga
    // .select() -> Dopo aver inserito, dammi indietro i dati creati
    // .single() -> È una riga sola
    final response = await supabase.from('household').insert({
      'name': name,
      'address': address,
    }).select().single();

    return response['id']; // Restituisco solo l'ID
  }

  // 2. AGGIUNGI UN MEMBRO ALLA CASA
  Future<void> addMember({
    required String householdId,
    required String userId,
    required String role, 
  }) async {
    await supabase.from('household_member').insert({
      'household_id': householdId,
      'user_id': userId,
      'role': role,
      'member_status': 'ACTIVE',
    });
  }

  // 3. SCARICA TUTTE LE CASE DI UN UTENTE
  Future<List<Household>> getHouseholdsForUser(String userId) async {
    try {
      // L'ID dell'utente è nella tabella di collegamento 'household_member'.
      
      // usiamo householdmember per i dati della casa
      final response = await supabase.from('household_member').select(
        'household(*)' // <-"Prendi tutti i campi (*) della tabella collegata 'household'"
      ).eq('user_id', userId);

      // Ora 'response' è una lista di membri. Ognuno ha dentro un pezzo chiamato 'household'.
      // Dobbiamo estrarre solo quel pezzo.
      
      // Creiamo una lista vuota dove mettere le case
      final List<Household> caseTrovate = [];

      for (var riga in response) {
        // 'riga' è il membro. 'riga['household']' è la casa.
        if (riga['household'] != null) {
          // Usiamo lo stampino Household.fromJson per creare l'oggetto
          caseTrovate.add(Household.fromJson(riga['household']));
        }
      }

      return caseTrovate;

    } catch (e) {
      // prima era presente solo "print", sostituita da "debugPrint"
      // ci servirà quando l'app sarà in fase di produzione, poichè con questo eviteremo problemi legati alla sicurezza dei dati
      debugPrint('Errore recupero case: $e'); 
      return []; // Se fallisce, restituisci lista vuota
    }
  }
}