import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/features/household/data/models/household.dart';
import 'package:everyday_app/features/household/presentation/providers/household_providers.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import 'package:everyday_app/shared/models/diet_document.dart';
import 'package:everyday_app/shared/services/auth_service.dart';

final currentUserProvider = Provider<User?>((ref) {
  final appContext = ref.watch(appContextProvider);
  return appContext.currentUser ?? AuthService().currentUser;
});

final currentHouseholdIdProvider = StateProvider<String?>((ref) {
  final appContext = ref.watch(appContextProvider);
  return appContext.householdId;
});

final currentHouseholdProvider = FutureProvider<Household?>((ref) async {
  final appContext = ref.watch(appContextProvider);
  final selectedHousehold = appContext.household;
  final selectedHouseholdId = appContext.householdId;
  if (selectedHousehold != null &&
      (selectedHouseholdId == null ||
          selectedHousehold.id == selectedHouseholdId)) {
    return selectedHousehold;
  }

  final householdService = ref.watch(householdServiceProvider);
  final households = await householdService.getMyHouseholds();
  if (households.isEmpty) {
    return null;
  }

  if (selectedHouseholdId == null) {
    return households.first;
  }

  for (final household in households) {
    if (household.id == selectedHouseholdId) {
      return household;
    }
  }

  return households.first;
});

final householdMembersProvider = FutureProvider<List<HouseholdMember>>((
  ref,
) async {
  final currentHousehold = await ref.watch(currentHouseholdProvider.future);
  if (currentHousehold == null) {
    return [];
  }

  final householdService = ref.watch(householdServiceProvider);
  return householdService.getMembers(currentHousehold.id);
});

final householdMembersStreamProvider = StreamProvider<List<HouseholdMember>>((
  ref,
) {
  final householdId = ref.watch(currentHouseholdIdProvider);

  if (householdId == null || householdId.isEmpty) {
    return const Stream<List<HouseholdMember>>.empty();
  }

  final repository = ref.watch(householdMemberRepositoryProvider);
  return repository.watchMembers(householdId);
});

final dietStreamProvider = StreamProvider<DietDocument?>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider);

  if (householdId == null || householdId.isEmpty) {
    return const Stream<DietDocument?>.empty();
  }

  final repository = ref.watch(dietRepositoryProvider);
  return repository.watchDiet(householdId);
});
