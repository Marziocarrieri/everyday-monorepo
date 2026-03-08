import 'package:everyday_app/features/fridge/data/models/area_type.dart';
import 'package:everyday_app/features/fridge/data/models/fridge_item.dart';
import 'package:everyday_app/features/fridge/data/repositories/fridge_repository.dart';

class PantryService {
  final FridgeRepository _repository;

  PantryService(this._repository);

  Future<List<FridgeItem>> getItems(String householdId, AreaType area) {
    return _repository.getItems(householdId, area);
  }

  Future<void> addItem({
    required String householdId,
    required String name,
    required AreaType area,
    int? quantity,
    int? weight,
    String? unit,
    DateTime? expirationDate,
  }) {
    return _repository.addItem(
      householdId: householdId,
      name: name,
      area: area,
      quantity: quantity,
      weight: weight,
      unit: unit,
      expirationDate: expirationDate,
    );
  }

  Future<void> deleteItem(String itemId) {
    return _repository.deleteItem(itemId);
  }

  Future<void> updateItem(FridgeItem updatedItem) {
    return _repository.updateItem(updatedItem);
  }
}
