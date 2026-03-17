import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/fridge/data/models/fridge_item.dart';
import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/domain/services/pantry_service.dart';
import 'package:everyday_app/features/fridge/domain/services/shopping_service.dart';

final pantryServiceProvider = Provider<PantryService>((ref) {
  final repository = ref.watch(fridgeRepositoryProvider);
  return PantryService(repository);
});

final fridgeItemsProvider = FutureProvider.family<List<FridgeItem>, AreaType>((
  ref,
  area,
) async {
  final pantryService = ref.watch(pantryServiceProvider);
  final householdId = AppContext.instance.requireHouseholdId();
  return pantryService.getItems(householdId, area);
});

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  final repository = ref.watch(shoppingRepositoryProvider);
  return ShoppingService(repository);
});

final shoppingItemsStreamProvider =
    StreamProvider.family<List<ShoppingItem>, String>((ref, householdId) {
  final repository = ref.watch(shoppingRepositoryProvider);
  return repository.watchShoppingItems(householdId);
});

final pantryItemsStreamProvider =
    StreamProvider.family<List<FridgeItem>, String>((ref, householdId) {
  final repository = ref.watch(fridgeRepositoryProvider);
  return repository.watchPantryItems(householdId);
});

// --- PROVIDER FILTRATI PER LISTA ATTIVA E STORICO ---
final activeShoppingItemsProvider = Provider.family<AsyncValue<List<ShoppingItem>>, String>((ref, householdId) {
  final itemsAsync = ref.watch(shoppingItemsStreamProvider(householdId));
  
  return itemsAsync.whenData((items) {
    // Mostra tutto TRANNE quelli nello storico
    return items.where((item) => item.status != 'BOUGHT').toList();
  });
});

final historyShoppingItemsProvider = Provider.family<AsyncValue<List<ShoppingItem>>, String>((ref, householdId) {
  final itemsAsync = ref.watch(shoppingItemsStreamProvider(householdId));
  
  return itemsAsync.whenData((items) {
    // Mostra SOLO quelli nello storico
    return items.where((item) => item.status == 'BOUGHT').toList();
  });
});
