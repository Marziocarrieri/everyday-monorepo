import 'package:flutter/foundation.dart';

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
    required String role,
  }) async {
    final normalizedInviteCode = inviteCode.trim().toUpperCase();
    final roleForInsert = role.trim().toUpperCase();

    if (roleForInsert.isEmpty) {
      throw Exception('Invite role missing');
    }

    debugPrint('CREATE INVITE ROLE: $roleForInsert');

    final inserted = await supabase
        .from('household_invite')
        .upsert({
          'household_id': householdId,
          'invite_code': normalizedInviteCode,
          'role': roleForInsert,
        }, onConflict: 'household_id')
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
