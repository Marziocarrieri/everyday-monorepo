import 'package:flutter/foundation.dart'; // Per debugPrint
import '../models/household.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart'; 
import '../../../../shared/repositories/supabase_client.dart';

class HouseholdJoinResult {
  final String membershipId;
  final String householdId;

  const HouseholdJoinResult({
    required this.membershipId,
    required this.householdId,
  });
}

class HouseholdRepository {

  // Crea una nuova casa
  Future<String> createHousehold(String name, String createdBy) async {
    final response = await supabase.from('household').insert({
      'name': name,
      'created_by': createdBy,
    }).select('id').single();

    return response['id'];
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

  Future<HouseholdJoinResult> joinByInviteCode({
    required String userId,
    required String inviteCode,
    required String role,
  }) async {
    final inviteRow = await supabase
        .from('household_invite')
        .select('household_id')
        .eq('invite_code', inviteCode)
        .maybeSingle();

    if (inviteRow == null) {
      throw Exception('Invalid invite code');
    }

    final inviteMap = Map<String, dynamic>.from(inviteRow);
    final householdId = inviteMap['household_id'] as String?;
    if (householdId == null || householdId.isEmpty) {
      throw Exception('Invalid invite code');
    }

    final membershipRow = await supabase
        .from('household_member')
        .insert({
          'user_id': userId,
          'household_id': householdId,
          'role': role,
        })
        .select('id, household_id')
        .single();

    final membershipMap = Map<String, dynamic>.from(membershipRow);
    final membershipId = membershipMap['id'] as String?;
    final joinedHouseholdId = membershipMap['household_id'] as String?;

    if (membershipId == null || joinedHouseholdId == null) {
      throw Exception('Membership creation failed');
    }

    return HouseholdJoinResult(
      membershipId: membershipId,
      householdId: joinedHouseholdId,
    );
  }
}