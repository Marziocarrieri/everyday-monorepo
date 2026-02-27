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
      print('APP CONTEXT ERROR → householdId missing');
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
  }

  void clear() {
    currentUser = null;
    profile = null;
    household = null;
    userId = null;
    householdId = null;
    membershipId = null;
  }
}
