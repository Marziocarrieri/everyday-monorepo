import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/providers/app_state_providers.dart';
import 'package:everyday_app/features/fridge/presentation/providers/fridge_providers.dart';
import 'package:everyday_app/features/household/presentation/providers/household_providers.dart';
import 'package:everyday_app/features/tasks/presentation/providers/task_providers.dart';

final isSwitchingHouseholdProvider = StateProvider<bool>((ref) => false);

final householdRuntimeControllerProvider = Provider<HouseholdRuntimeController>(
  (ref) {
    return HouseholdRuntimeController();
  },
);

class HouseholdRuntimeController {
  Future<void> switchHousehold(WidgetRef ref, String newHouseholdId) async {
    final isSwitching = ref.read(isSwitchingHouseholdProvider);
    if (isSwitching) {
      return;
    }

    final previousHouseholdId = ref.read(currentHouseholdIdProvider);
    if (previousHouseholdId == newHouseholdId) {
      return;
    }

    ref.read(isSwitchingHouseholdProvider.notifier).state = true;

    try {
      // STEP A: invalidate providers bound to the previous household context.
      ref.invalidate(householdMembersStreamProvider);
      ref.invalidate(tasksStreamProvider);
      ref.invalidate(dietStreamProvider);

      if (previousHouseholdId != null && previousHouseholdId.isNotEmpty) {
        ref.invalidate(roomsStreamProvider(previousHouseholdId));
        ref.invalidate(floorsStreamProvider(previousHouseholdId));
        ref.invalidate(pantryItemsStreamProvider(previousHouseholdId));
        ref.invalidate(shoppingItemsStreamProvider(previousHouseholdId));
      }

      // STEP B: only after invalidation, publish the new active household.
      ref.read(currentHouseholdIdProvider.notifier).state = newHouseholdId;
      AppContext.instance.setActiveHousehold(newHouseholdId);

      // STEP C: allow disposal/teardown to settle before prewarming.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // STEP D: prewarm critical providers used by first-visible screens.
      ref.read(householdMembersStreamProvider);
      ref.read(roomsStreamProvider(newHouseholdId));
      ref.read(tasksStreamProvider);
    } finally {
      // STEP E: unblock interactions.
      ref.read(isSwitchingHouseholdProvider.notifier).state = false;
    }
  }
}
