import '../../../../shared/repositories/supabase_client.dart';

class HouseholdMemberRepository {
  Future<List<Map<String, dynamic>>> getMembershipRowsForUser(String userId) async {
    final response = await supabase
        .from('household_member')
        .select('id, household_id, role')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getHouseholdsForUser(String userId) async {
    final response = await supabase
        .from('household_member')
        .select('household_id, household(id, name)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteMembershipById(String membershipId) async {
    await supabase.from('household_member').delete().eq('id', membershipId);
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
