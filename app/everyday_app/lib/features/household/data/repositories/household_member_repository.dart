import 'package:flutter/foundation.dart';

import '../../../../shared/repositories/supabase_client.dart';

class HouseholdMemberRepository {
  Future<List<Map<String, dynamic>>> getMembershipRowsForUser(String userId) async {
    final response = await supabase
        .from('household_member')
        .select('id, household_id, role')
        .eq('user_id', userId)
        .eq('member_status', 'ACTIVE');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getHouseholdsForUser(String userId) async {
    final response = await supabase
        .from('household_member')
        .select('household_id, household(id, name)')
        .eq('user_id', userId)
        .eq('member_status', 'ACTIVE');

    final seenHouseholdIds = <String>{};
    final uniqueRows = <Map<String, dynamic>>[];

    for (final row in List<Map<String, dynamic>>.from(response)) {
      final householdId = row['household_id'] as String?;
      if (householdId == null || householdId.isEmpty) {
        continue;
      }

      if (seenHouseholdIds.add(householdId)) {
        uniqueRows.add(row);
      }
    }

    return uniqueRows;
  }

  Future<void> deleteMembershipById({
    required String membershipId,
    required String userId,
    required String householdId,
  }) async {
    debugPrint(
      'LEAVE REPOSITORY MEMBERSHIP ID: membership_id=$membershipId user_id=$userId household_id=$householdId',
    );
    debugPrint(
      'LEAVE REPOSITORY AUTH UID: ${supabase.auth.currentUser?.id}',
    );

    debugPrint(
      'LEAVE HOUSEHOLD REQUEST: membership_id=$membershipId user_id=$userId household_id=$householdId',
    );

    final deleteResponse = await supabase
        .from('household_member')
        .delete()
        .eq('id', membershipId)
        .eq('user_id', userId)
        .select('id');

    final deletedCount = List<Map<String, dynamic>>.from(deleteResponse).length;
    debugPrint('LEAVE HOUSEHOLD DELETE RESULT: deleted_count=$deletedCount');

    final remainingResponse = await supabase
        .from('household_member')
        .select('id')
        .eq('user_id', userId)
        .eq('household_id', householdId);
    final remainingCount =
        List<Map<String, dynamic>>.from(remainingResponse).length;
    debugPrint('MEMBERSHIP ROW COUNT AFTER LEAVE: $remainingCount');

    if (deletedCount == 0) {
      throw Exception('Leave household failed: membership not deleted');
    }
  }

  Future<void> deleteMyMembership(
    String householdId,
    String userId,
  ) async {
    debugPrint(
      'LEAVE HOUSEHOLD REQUEST: user_id=$userId household_id=$householdId',
    );

    final deleteResponse = await supabase
        .from('household_member')
        .delete()
        .eq('household_id', householdId)
        .eq('user_id', userId)
        .select('id');

    final deletedCount = List<Map<String, dynamic>>.from(deleteResponse).length;
    debugPrint('LEAVE HOUSEHOLD DELETE RESULT: deleted_count=$deletedCount');

    final remainingResponse = await supabase
        .from('household_member')
        .select('id')
        .eq('user_id', userId)
        .eq('household_id', householdId);
    final remainingCount =
        List<Map<String, dynamic>>.from(remainingResponse).length;
    debugPrint('MEMBERSHIP ROW COUNT AFTER LEAVE: $remainingCount');

    if (deletedCount == 0) {
      throw Exception('Leave household failed: membership not deleted');
    }
  }

  Future<void> deleteMembershipsByHousehold(String householdId) async {
    await supabase
        .from('household_member')
        .delete()
        .eq('household_id', householdId);
  }

  Future<void> updateMembership(
    String membershipId,
    Map<String, dynamic> payload,
  ) async {
    await supabase
        .from('household_member')
        .update(payload)
        .eq('id', membershipId);
  }
}
