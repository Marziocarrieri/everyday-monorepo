import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/household.dart';
import '../models/user.dart';

class ActiveMembership {
  final String id;
  final String householdId;
  final String role;
  final String? nickname;
  final String? avatarUrl;

  const ActiveMembership({
    required this.id,
    required this.householdId,
    required this.role,
    this.nickname,
    this.avatarUrl,
  });

  factory ActiveMembership.fromMap(Map<String, dynamic> map) {
    return ActiveMembership(
      id: map['id'] as String,
      householdId: map['household_id'] as String,
      role: (map['role'] as String?) ?? 'Member',
      nickname: map['nickname'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class AppContext extends ChangeNotifier {
  static final AppContext instance = AppContext._internal();
  AppContext._internal();

  User? currentUser;
  AppUser? profile;
  Household? household;

  String? userId;
  String? householdId;
  String? membershipId;
  ActiveMembership? activeMembership;

  bool get isReady => userId != null && householdId != null;

  void setUser(String id) {
    userId = id;
    notifyListeners();
  }

  void setHousehold(String householdId) {
    setActiveHousehold(householdId);
  }

  void setActiveHousehold(String? householdId) {
    this.householdId = householdId;
    notifyListeners();
    unawaited(_syncMembershipForActiveHousehold());
  }

  void setMembership(String? membershipId) {
    this.membershipId = membershipId;
    if (membershipId == null) {
      activeMembership = null;
    }
    notifyListeners();
  }

  Future<void> _syncMembershipForActiveHousehold() async {
    final currentUserId = userId;
    final currentHouseholdId = householdId;

    if (currentUserId == null || currentHouseholdId == null) {
      membershipId = null;
      activeMembership = null;
      notifyListeners();
      return;
    }

    final row = await Supabase.instance.client
        .from('household_member')
        .select('id, household_id, role, nickname, avatar_url')
        .eq('user_id', currentUserId)
        .eq('household_id', currentHouseholdId)
        .maybeSingle();

    if (currentUserId != userId || currentHouseholdId != householdId) {
      return;
    }

    if (row == null) {
      membershipId = null;
      activeMembership = null;
      notifyListeners();
      return;
    }

    final mapped = Map<String, dynamic>.from(row);
    membershipId = mapped['id'] as String?;
    activeMembership = ActiveMembership.fromMap(mapped);
    notifyListeners();
  }

  String requireHouseholdId() {
    final id = householdId;
    if (id == null) {
      throw Exception('Household context not initialized');
    }
    return id;
  }

  void setSession({
    required User authUser,
    required AppUser profile,
    required Household? household,
    required String? membershipId,
  }) {
    currentUser = authUser;
    this.profile = profile;
    this.household = household;
    userId = authUser.id;
    householdId = household?.id;
    this.membershipId = membershipId;
    activeMembership = null;
    notifyListeners();

    if (membershipId != null) {
      unawaited(reloadMemberContext());
    }
  }

  Future<void> reloadMemberContext() async {
    final currentMembershipId = membershipId;
    if (currentMembershipId == null) {
      activeMembership = null;
      notifyListeners();
      return;
    }

    final row = await Supabase.instance.client
        .from('household_member')
        .select('id, household_id, role, nickname, avatar_url')
        .eq('id', currentMembershipId)
        .maybeSingle();

    if (row == null) {
      activeMembership = null;
      notifyListeners();
      return;
    }

    final mapped = Map<String, dynamic>.from(row);
    activeMembership = ActiveMembership.fromMap(mapped);
    notifyListeners();
  }

  void clear() {
    currentUser = null;
    profile = null;
    household = null;
    userId = null;
    householdId = null;
    membershipId = null;
    activeMembership = null;
    notifyListeners();
  }
}
