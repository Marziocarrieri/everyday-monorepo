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

  Future<void> _ensureUserProfileExists({
    required String userId,
    required String? email,
  }) async {
    final existingProfile = await supabase
        .from('users_profile')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existingProfile != null) {
      return;
    }

    try {
      await supabase.from('users_profile').insert({
        'id': userId,
        'email': email,
      });
    } catch (error) {
      // If another request inserted it concurrently, continue.
      final message = error.toString().toLowerCase();
      if (message.contains('duplicate key value')) {
        return;
      }
      rethrow;
    }
  }

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
          .eq('household_id', householdId);

      // Usiamo lo stampino HouseholdMember.fromJson che sa gestire questa struttura complessa
      return (response as List)
          .map((row) => _normalizeMemberRow(Map<String, dynamic>.from(row)))
          .map(HouseholdMember.fromJson)
          .toList();

    } catch (e) {
      debugPrint('Errore recupero membri: $e');
      return [];
    }
  }

  Future<HouseholdJoinResult> joinByInviteCode({
    required String userId,
    required String? userEmail,
    required String inviteCode,
    required String selectedRole,
  }) async {
    debugPrint("ROLE SELECTED AT JOIN: $selectedRole");

    final normalizedSelectedRole = selectedRole.trim().toUpperCase();
    late final String role;
    switch (normalizedSelectedRole) {
      case 'HOST':
        role = 'HOST';
        break;
      case 'COHOST':
      case 'CO_HOST':
        role = 'COHOST';
        break;
      case 'PERSONNEL':
        role = 'PERSONNEL';
        break;
      default:
        throw Exception('Invalid selected role');
    }

    final normalizedInviteCode = inviteCode.trim().toUpperCase();

    late final Map<String, dynamic> inviteMap;
    try {
      final inviteRow = await supabase
          .from('household_invite')
          .select('household_id, role')
          .eq('invite_code', normalizedInviteCode)
          .single();
      inviteMap = Map<String, dynamic>.from(inviteRow);
      debugPrint("ROLE FROM INVITE: ${inviteMap['role']}");
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('0 rows') || message.contains('no rows')) {
        throw Exception('Invalid invite code');
      }
      rethrow;
    }

    final householdIdFromInvite = inviteMap['household_id'] as String?;
    if (householdIdFromInvite == null || householdIdFromInvite.isEmpty) {
      throw Exception('Invalid invite code');
    }

    await _ensureUserProfileExists(userId: userId, email: userEmail);

    final existingMembershipRows = await supabase
        .from('household_member')
        .select('id, household_id')
        .eq('user_id', userId)
        .eq('household_id', householdIdFromInvite)
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

    final bool isPersonnel = role == 'PERSONNEL';
    debugPrint("ROLE WRITTEN TO MEMBERSHIP: $role");

    final membershipRow = await supabase
        .from('household_member')
        .insert({
          'user_id': userId,
          'household_id': householdIdFromInvite,
          'role': role,
          'member_status': 'ACTIVE',
          'is_personnel': isPersonnel,
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