import 'package:flutter/foundation.dart';

bool isTaskCreatedByCurrentUser({
  required String? taskCreatedBy,
  required String? currentUserId,
  required String? currentMemberId,
}) {
  final normalizedTaskCreatedBy = (taskCreatedBy ?? '').trim();
  final normalizedCurrentUserId = (currentUserId ?? '').trim();
  final normalizedCurrentMemberId = (currentMemberId ?? '').trim();

  final matchesMembershipId = normalizedCurrentMemberId.isNotEmpty &&
      normalizedTaskCreatedBy == normalizedCurrentMemberId;
  final matchesUserId = normalizedCurrentUserId.isNotEmpty &&
      normalizedTaskCreatedBy == normalizedCurrentUserId;

  final result = normalizedTaskCreatedBy.isNotEmpty &&
      (matchesMembershipId || matchesUserId);

  if (kDebugMode) {
    debugPrint(
      'TASK CREATOR CHECK -> taskCreatedBy=$normalizedTaskCreatedBy | currentUserId=$normalizedCurrentUserId | currentMemberId=$normalizedCurrentMemberId | result=$result',
    );
  }

  return result;
}