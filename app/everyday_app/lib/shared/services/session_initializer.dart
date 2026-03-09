import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_context.dart';
import '../../features/household/data/models/household.dart';
import '../models/user.dart';

enum BootstrapState {
  noSession,
  noHousehold,
  ready,
}

class SessionInitializer {
  Future<void> ensureProfileForCurrentUser({
    required String name,
    required String email,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await supabase.from('users_profile').upsert({
      'id': user.id,
      'name': name,
      'email': email,
    });
  }

  Future<BootstrapState> initialize() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      AppContext.instance.clear();
      print('BOOTSTRAP → user: none');
      print('BOOTSTRAP → profile: none');
      print('BOOTSTRAP → household: none');
      return BootstrapState.noSession;
    }

    final profileRow = await supabase
        .from('users_profile')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (profileRow == null) {
      AppContext.instance.clear();
      print('BOOTSTRAP → user: ${user.id}');
      print('BOOTSTRAP → profile: missing');
      print('BOOTSTRAP → household: none');
      return BootstrapState.noSession;
    }

    final membershipRows = await supabase
        .from('household_member')
        .select('id, household_id')
      .eq('user_id', user.id);

    final memberships = List<Map<String, dynamic>>.from(membershipRows);

    if (memberships.isEmpty) {
      final profile = AppUser.fromJson(Map<String, dynamic>.from(profileRow));
      AppContext.instance.setSession(
        authUser: user,
        profile: profile,
        household: null,
        membershipId: null,
      );
      print('BOOTSTRAP → user: ${user.id}');
      print('BOOTSTRAP → profile: ${profile.id}');
      print('BOOTSTRAP → household: none');
      return BootstrapState.noHousehold;
    }

    final currentActiveHouseholdId = AppContext.instance.householdId;
    final persistedHouseholdId = await AppContext.instance
        .getPersistedLastHouseholdId();
    final preferredHouseholdId =
        currentActiveHouseholdId ?? persistedHouseholdId;

    Map<String, dynamic>? selectedMembership;
    if (preferredHouseholdId != null) {
      for (final membership in memberships) {
        if (membership['household_id'] == preferredHouseholdId) {
          selectedMembership = membership;
          break;
        }
      }
    }

    selectedMembership ??= memberships.first;

    final membership = Map<String, dynamic>.from(selectedMembership);
    final householdId = membership['household_id'] as String;
    final householdMap = await supabase
        .from('household')
        .select('*')
        .eq('id', householdId)
        .single();

    final household = Household.fromJson(householdMap);
    final profile = AppUser.fromJson(Map<String, dynamic>.from(profileRow));

    AppContext.instance.setSession(
      authUser: user,
      profile: profile,
      household: household,
      membershipId: membership['id'] as String?,
    );

    print('BOOTSTRAP → user: ${user.id}');
    print('BOOTSTRAP → profile: ${profile.id}');
    print('BOOTSTRAP → household: ${household.id}');

    return BootstrapState.ready;
  }
}
