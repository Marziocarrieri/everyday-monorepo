import 'package:flutter/foundation.dart'; // Per debugPrint
import '../models/household.dart';
import '../models/household_member.dart'; 
import 'supabase_client.dart';

class HouseholdRepository {

  // Crea una nuova casa
  Future<String> createHousehold(String name, String address) async {
    final response = await supabase.from('household').insert({
      'name': name,
      'address': address,
    }).select('id').single();

    return response['id'];
  }

  // Aggiungi membro
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

  // Le mie case
  Future<List<Household>> getHouseholdsForUser(String userId) async {
    try {
      final response = await supabase.from('household_member').select(
        'household(*)' 
      ).eq('user_id', userId);

      final List<Household> households = List<Map<String, dynamic>>.from(response)
          .map((row) => Household.fromJson(row['household']))
          .toList();

      return households;
    } catch (e) {
      debugPrint('Errore recupero case: $e');
      return [];
    }
  }

  // Vedere chi abita in casa (e assegnare i Task)
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    try {
      // Usiamo una join
      // .select('*, users_profile(*)')
      // Significa: "Prendi tutti i dati del membro (*) E POI vai nella tabella
      // users_profile e prendi anche tutti i dati anagrafici (*)"
      final response = await supabase
          .from('household_member')
          .select('*, users_profile(*)') 
          .eq('household_id', householdId);

      // Usiamo lo stampino HouseholdMember.fromJson che sa gestire questa struttura complessa
      return (response as List)
          .map((json) => HouseholdMember.fromJson(json))
          .toList();

    } catch (e) {
      debugPrint('Errore recupero membri: $e');
      return [];
    }
  }
}