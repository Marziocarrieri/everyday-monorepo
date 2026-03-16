import 'package:flutter/foundation.dart';

import 'package:everyday_app/features/personnel/data/models/household_member.dart'; // Importiamo il membro perché è la persona assegnata

class TaskAssignment {
  final String id;
  final String taskId;
  final String memberId;
  final String? roomId;
  final String status; // 'TODO', 'DONE', 'SKIPPED'
  final String? note;
  final DateTime? completedAt;
  final HouseholdMember? member; // Dettagli di chi lo deve fare

  TaskAssignment({
    required this.id,
    required this.taskId,
    required this.memberId,
    this.roomId,
    required this.status,
    this.note,
    this.completedAt,
    this.member,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Task assignment row is missing id');
    }

    final taskId = _asString(json['task_id']);
    if (taskId.isEmpty) {
      throw const FormatException('Task assignment row is missing task_id');
    }

    final memberId = _asString(json['member_id']);
    if (memberId.isEmpty) {
      throw const FormatException('Task assignment row is missing member_id');
    }

    final memberJson = _extractMemberJson(json['household_member']);
    HouseholdMember? member;
    if (memberJson != null) {
      try {
        member = HouseholdMember.fromJson(memberJson);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'TASK_ASSIGNMENT_SKIP_MEMBER_PARSE id=$id member_id=$memberId error=$error',
          );
        }
      }
    }

    return TaskAssignment(
      id: id,
      taskId: taskId,
      memberId: memberId,
      roomId: _asNullableString(json['room_id']),
      status: _asString(json['status'], fallback: 'TODO'),
      note: _asNullableString(json['note']),
      completedAt: _parseDateTime(json['completed_at']),
      member: member,
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString();
    if (normalized.isEmpty) return fallback;
    return normalized;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic>? _extractMemberJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }
}