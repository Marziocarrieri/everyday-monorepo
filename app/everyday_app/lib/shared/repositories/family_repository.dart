
import 'package:flutter/foundation.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'supabase_client.dart';
import '../../core/app_context.dart';


class FamilyRepository {
  /// Fetches all members for a specific household ID.
  /// Maps the database response directly to the existing HouseholdMember model.
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    try {
      debugPrint('HOUSEHOLD MEMBERS LOAD → household: $householdId');

      final String? currentUid = AppContext.instance.userId;

      var query = supabase
          .from('household_member')
          .select('*, profile:users_profile(*)')
          .eq('household_id', householdId)
          .inFilter('role', ['HOST', 'COHOST']);

      if (currentUid != null) {
        query = query.neq('user_id', currentUid);
      }

      final response = await query.order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED MEMBER JSON: $row');
      }

      return data
          .map((json) => HouseholdMember.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching household members: $e');
      rethrow; 
    }
  }
}


// 74652332-ce87-4feb-83cf-3bd2afbd3f4f

// 3177eba0-2caa-4aec-b7d0-6acc806088dd