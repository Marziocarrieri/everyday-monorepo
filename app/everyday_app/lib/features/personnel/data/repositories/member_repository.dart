// 


import 'package:flutter/foundation.dart';
import '../models/household_member.dart';
import '../../../../shared/repositories/supabase_client.dart';

class MemberRepository {
  String _resolveDisplayName({
    String? nickname,
    String? name,
    String? email,
  }) {
    for (final candidate in [nickname, name, email]) {
      final normalized = candidate?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return 'Unknown';
  }

  Map<String, dynamic> _normalizeMemberRow(Map<String, dynamic> row) {
    final normalizedRow = Map<String, dynamic>.from(row);
    final rawProfile = normalizedRow['profile'];

    final profile = rawProfile is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawProfile)
        : rawProfile is Map
            ? Map<String, dynamic>.from(rawProfile)
            : <String, dynamic>{};

    final membershipNickname = normalizedRow['nickname'] as String?;
    final profileName = profile['name'] as String?;
    final profileEmail = profile['email'] as String?;

    profile['id'] ??= normalizedRow['user_id'];
    profile['name'] = _resolveDisplayName(
      nickname: membershipNickname,
      name: profileName,
      email: profileEmail,
    );

    if (profileEmail != null && profileEmail.trim().isNotEmpty) {
      profile['email'] = profileEmail;
    }

    final membershipAvatarUrl = normalizedRow['avatar_url'] as String?;
    final profileAvatarUrl = profile['avatar_url'] as String?;
    if ((profileAvatarUrl == null || profileAvatarUrl.trim().isEmpty) &&
        membershipAvatarUrl != null &&
        membershipAvatarUrl.trim().isNotEmpty) {
      profile['avatar_url'] = membershipAvatarUrl;
    }

    normalizedRow['profile'] = profile;
    return normalizedRow;
  }

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
          .select('''
            id,
            user_id,
            household_id,
            role,
            member_status,
            nickname,
            avatar_url,
            is_personnel,
            personnel_type,
            profile:users_profile(
              id,
              name,
              email
            )
          ''')
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
          .map(_normalizeMemberRow)
          .map(HouseholdMember.fromJson)
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