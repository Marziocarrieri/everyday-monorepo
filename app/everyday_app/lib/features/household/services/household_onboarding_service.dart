import 'dart:typed_data';

import 'package:everyday_app/shared/repositories/avatar_storage_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_member_repository.dart';

class HouseholdOnboardingService {
  final HouseholdMemberRepository _memberRepository =
      HouseholdMemberRepository();
  final AvatarStorageRepository _avatarStorageRepository =
      AvatarStorageRepository();

  Future<String?> uploadAvatarIfNeeded({
    required Uint8List? bytes,
    required String? householdId,
    required String? membershipId,
  }) async {
    if (bytes == null || householdId == null || membershipId == null) {
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$householdId/$membershipId/$timestamp.jpg';

    await _avatarStorageRepository.uploadAvatar(path: path, bytes: bytes);
    return _avatarStorageRepository.getPublicUrl(path);
  }

  Future<void> saveMemberProfile({
    required String membershipId,
    required String nickname,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{'nickname': nickname};
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }

    await _memberRepository.updateMembership(membershipId, payload);
  }
}
