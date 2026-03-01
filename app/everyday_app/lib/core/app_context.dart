import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/household.dart';
import '../models/user.dart';

class AppContext {
  static final AppContext instance = AppContext._internal();
  AppContext._internal();

  User? currentUser;
  AppUser? profile;
  Household? household;

  String? userId;
  String? householdId;
  String? membershipId;
  String? nickname;

  bool get isReady => userId != null && householdId != null;

  void setUser(String id) {
    userId = id;
  }

  void setHousehold(String householdId) {
    this.householdId = householdId;
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
    nickname = null;
  }

  Future<void> reloadMemberContext() async {
    final currentMembershipId = membershipId;
    if (currentMembershipId == null) {
      nickname = null;
      return;
    }

    final row = await Supabase.instance.client
        .from('household_member')
        .select('nickname')
        .eq('id', currentMembershipId)
        .maybeSingle();

    if (row == null) {
      nickname = null;
      return;
    }

    final mapped = Map<String, dynamic>.from(row);
    nickname = mapped['nickname'] as String?;
  }

  void clear() {
    currentUser = null;
    profile = null;
    household = null;
    userId = null;
    householdId = null;
    membershipId = null;
    nickname = null;
  }
}
