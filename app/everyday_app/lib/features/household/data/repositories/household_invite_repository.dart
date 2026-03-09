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
    final code = mapped['invite_code'] as String?;
    if (code == null) {
      return null;
    }

    return code.trim().toUpperCase();
  }

  Future<String> createInviteCode({
    required String householdId,
    required String inviteCode,
  }) async {
    final normalizedInviteCode = inviteCode.trim().toUpperCase();

    final inserted = await supabase
        .from('household_invite')
        .insert({
          'household_id': householdId,
          'invite_code': normalizedInviteCode,
        })
        .select('invite_code')
        .single();

    final mapped = Map<String, dynamic>.from(inserted);
    final createdCode = mapped['invite_code'] as String?;
    if (createdCode == null || createdCode.isEmpty) {
      throw Exception('Invite code creation failed');
    }

    return createdCode.trim().toUpperCase();
  }
}
