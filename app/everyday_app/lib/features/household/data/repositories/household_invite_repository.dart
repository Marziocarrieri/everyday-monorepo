import '../../../../shared/repositories/supabase_client.dart';

class HouseholdInviteRepository {
  Future<void> deleteByHousehold(String householdId) async {
    await supabase
        .from('household_invite')
        .delete()
        .eq('household_id', householdId);
  }

  Future<String?> getInviteCodeForHousehold(String householdId) async {
    final existing = await supabase
        .from('household_invite')
        .select('invite_code')
        .eq('household_id', householdId)
        .maybeSingle();

    if (existing == null) {
      return null;
    }

    final mapped = Map<String, dynamic>.from(existing);
    return mapped['invite_code'] as String?;
  }

  Future<String> createInviteCode({
    required String householdId,
    required String inviteCode,
  }) async {
    final inserted = await supabase
        .from('household_invite')
        .insert({'household_id': householdId, 'invite_code': inviteCode})
        .select('invite_code')
        .single();

    final mapped = Map<String, dynamic>.from(inserted);
    final createdCode = mapped['invite_code'] as String?;
    if (createdCode == null || createdCode.isEmpty) {
      throw Exception('Invite code creation failed');
    }

    return createdCode;
  }
}
