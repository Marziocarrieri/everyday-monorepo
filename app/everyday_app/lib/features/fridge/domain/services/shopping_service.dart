import 'package:everyday_app/features/fridge/data/models/shopping_item.dart';
import 'package:everyday_app/features/fridge/data/repositories/shopping_repository.dart';

class ShoppingService {
  final ShoppingRepository _repository;

  ShoppingService(this._repository);

  Future<void> addItem(
    String householdId,
    String name, {
    int quantity = 1,
  }) {
    return _repository.addItem(
      householdId,
      name,
      quantity: quantity,
    );
  }

  Future<List<ShoppingItem>> getList(String householdId) {
    return _repository.getList(householdId);
  }

  Future<void> toggleStatus(String itemId, String currentStatus) {
    return _repository.toggleStatus(itemId, currentStatus);
  }

  Future<void> deleteItem(String itemId) {
    return _repository.deleteItem(itemId);
  }

  Future<void> updateItem(ShoppingItem item) {
    return _repository.updateItem(item);
  }

  // --- NUOVI METODI PER LO STORICO ---
  Future<void> moveToHistory(String itemId) {
    return _repository.moveToHistory(itemId);
  }

  Future<void> restoreItem(String itemId) {
    return _repository.restoreItem(itemId);
  }
}
