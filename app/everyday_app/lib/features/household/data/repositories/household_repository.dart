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

      final seenHouseholdIds = <String>{};
      final households = <Household>[];

      for (final row in List<Map<String, dynamic>>.from(response)) {
        final householdJson = row['household'];
        if (householdJson is! Map<String, dynamic>) {
          continue;
        }

        final household = Household.fromJson(householdJson);
        if (seenHouseholdIds.add(household.id)) {
          households.add(household);
        }
      }

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
    final normalizedInviteCode = inviteCode.trim().toUpperCase();
    final normalizedRequestedRole = role.trim().toUpperCase();

    late final Map<String, dynamic> inviteMap;
    try {
      final inviteRow = await supabase
          .from('household_invite')
          .select('household_id, role')
          .eq('invite_code', normalizedInviteCode)
          .single();
      inviteMap = Map<String, dynamic>.from(inviteRow);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('0 rows') || message.contains('no rows')) {
        throw Exception('Invalid invite code');
      }
      rethrow;
    }

    final householdId = inviteMap['household_id'] as String?;
    if (householdId == null || householdId.isEmpty) {
      throw Exception('Invalid invite code');
    }

    final inviteRole = (inviteMap['role'] as String?)?.trim().toUpperCase();
    final effectiveRole =
        (inviteRole != null && inviteRole.isNotEmpty)
            ? inviteRole
            : normalizedRequestedRole;

    final existingMembershipRows = await supabase
        .from('household_member')
        .select('id, household_id')
        .eq('user_id', userId)
        .eq('household_id', householdId)
        .order('created_at', ascending: true)
        .limit(1);

    final existingMembershipList =
        List<Map<String, dynamic>>.from(existingMembershipRows);
    if (existingMembershipList.isNotEmpty) {
      final existingMembership = existingMembershipList.first;
      final existingMembershipId = existingMembership['id'] as String?;
      final existingHouseholdId = existingMembership['household_id'] as String?;

      if (existingMembershipId == null || existingHouseholdId == null) {
        throw Exception('Membership loading failed');
      }

      return HouseholdJoinResult(
        membershipId: existingMembershipId,
        householdId: existingHouseholdId,
      );
    }

    final membershipRow = await supabase
        .from('household_member')
        .insert({
          'user_id': userId,
          'household_id': householdId,
          'role': effectiveRole,
          'is_personnel': effectiveRole == 'PERSONNEL',
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