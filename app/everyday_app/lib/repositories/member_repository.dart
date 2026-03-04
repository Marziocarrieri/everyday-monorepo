// 


import 'package:flutter/foundation.dart';
import '../models/household_member.dart';
import 'supabase_client.dart';

class MemberRepository {
  /// Fetches all members for a specific household ID.
  /// Maps the database response directly to the existing HouseholdMember model.
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    try {
      debugPrint('HOUSEHOLD MEMBERS LOAD → household: $householdId');

      // 1. We select all columns from the 'household_member' table.
      // Based on your image, this includes: id, user_id, household_id, role, 
      // member_status, is_personnel, personnel_type, created_at, nickname, avatar_url.
      final response = await supabase
          .from('household_member')
          .select('*, profile:users_profile(*)')
          .eq('household_id', householdId)
          .eq('role', 'PERSONNEL')
          .order('created_at', ascending: true);

      // 2. Cast the response to a List of Maps
      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED MEMBER JSON: $row');
      }

      // 3. Map the JSON to your HouseholdMember model. 
      // This works as long as your model's fromJson matches these column names.
      return data
          .map((json) => HouseholdMember.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching household members: $e');
      // You could return an empty list here or rethrow depending on your UI needs
      rethrow; 
    }
  }
}


// 74652332-ce87-4feb-83cf-3bd2afbd3f4f

// 3177eba0-2caa-4aec-b7d0-6acc806088dd