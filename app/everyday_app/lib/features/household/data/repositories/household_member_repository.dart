import 'package:flutter/foundation.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';

import '../../../../shared/repositories/supabase_client.dart';

class HouseholdMemberRepository {
  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    final cachedRowsById = <String, Map<String, dynamic>>{};

    return supabase
        .from('household_member')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          final nextRowsById = <String, Map<String, dynamic>>{};

          for (final row in rows) {
            final incoming = Map<String, dynamic>.from(row);
            final id = incoming['id']?.toString();
            if (id == null || id.isEmpty) {
              continue;
            }

            final previous = cachedRowsById[id];
            nextRowsById[id] = previous == null
                ? incoming
                : <String, dynamic>{...previous, ...incoming};
          }

          cachedRowsById
            ..clear()
            ..addAll(nextRowsById);

          final membershipRows = cachedRowsById.values
              .where((row) => row['household_id'] == householdId)
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          final userIds = membershipRows
              .map((row) => row['user_id'])
              .whereType<String>()
              .toSet()
              .toList();

          final profilesByUserId = <String, Map<String, dynamic>>{};
          if (userIds.isNotEmpty) {
            final profilesResponse = await supabase
                .from('users_profile')
                .select('id, name, email')
                .inFilter('id', userIds);

            for (final profile
                in List<Map<String, dynamic>>.from(profilesResponse)) {
              final id = profile['id'] as String?;
              if (id == null) continue;
              profilesByUserId[id] = profile;
            }
          }

          return membershipRows.map((row) {
            final mapped = Map<String, dynamic>.from(row);
            final userId = mapped['user_id'] as String?;
            if (userId != null && profilesByUserId.containsKey(userId)) {
              mapped['profile'] = profilesByUserId[userId];
            }
            return HouseholdMember.fromJson(mapped);
          }).toList();
        });
  }

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
