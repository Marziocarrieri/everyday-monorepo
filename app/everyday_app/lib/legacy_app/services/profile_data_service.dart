import 'dart:typed_data';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/shared/repositories/avatar_storage_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_admin_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_invite_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_member_repository.dart';
import 'package:everyday_app/shared/services/auth_service.dart';

class ProfileDataService {
  final HouseholdMemberRepository _householdMemberRepository =
      HouseholdMemberRepository();
  final HouseholdInviteRepository _householdInviteRepository =
      HouseholdInviteRepository();
  final HouseholdAdminRepository _householdAdminRepository =
      HouseholdAdminRepository();
  final AvatarStorageRepository _avatarStorageRepository =
      AvatarStorageRepository();
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> loadMembershipRows(String userId) async {
    return _householdMemberRepository.getMembershipRowsForUser(userId);
  }

  Future<List<Map<String, dynamic>>> loadHouseholdsForUser(String userId) async {
    return _householdMemberRepository.getHouseholdsForUser(userId);
  }

  Future<void> removeMembership(String membershipId) async {
    await _householdMemberRepository.deleteMembershipById(membershipId);
  }

  Future<void> removeMembershipsByHousehold(String householdId) async {
    await _householdMemberRepository.deleteMembershipsByHousehold(householdId);
  }

  Future<void> deleteHousehold(String householdId) async {
    await _householdAdminRepository.deleteHousehold(householdId);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateNickname({
    required String membershipId,
    required String nickname,
  }) async {
    await _householdMemberRepository.updateMembership(membershipId, {
      'nickname': nickname,
    });
  }

  Future<void> updateAvatarUrl({
    required String membershipId,
    required String? avatarUrl,
  }) async {
    await _householdMemberRepository.updateMembership(membershipId, {
      'avatar_url': avatarUrl,
    });
  }

  Future<void> deleteInviteCodesForHousehold(String householdId) async {
    // Regeneration now uses upsert on household_id, so pre-delete is unnecessary.
    return;
  }

  Future<String?> getInviteCodeForHousehold(String householdId) async {
    return _householdInviteRepository.getInviteCodeForHousehold(householdId);
  }

  Future<String> createInviteCode({
    required String householdId,
    required String inviteCode,
    String? role,
  }) async {
    final normalizedRole =
        (role ?? AppContext.instance.activeMembership?.role ?? '')
            .trim()
            .toUpperCase();

    if (normalizedRole.isEmpty) {
      throw Exception('Invite role missing');
    }

    return _householdInviteRepository.createInviteCode(
      householdId: householdId,
      inviteCode: inviteCode,
      role: normalizedRole,
    );
  }

  Future<String> uploadAvatar({
    required String householdId,
    required String membershipId,
    required Uint8List fileBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$householdId/$membershipId/$timestamp.jpg';

    await _avatarStorageRepository.uploadAvatar(path: path, bytes: fileBytes);
    return _avatarStorageRepository.getPublicUrl(path);
  }

  Future<void> removeAvatarByPath(String path) async {
    await _avatarStorageRepository.removeAvatar(path);
  }
}
