import '../models/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class ShoppingService {
  final ShoppingRepository _repo = ShoppingRepository();

  // Aggiungere alla lista degli oggetti 
  // Lo stato iniziale è automatico (PENDING) nel database.
  Future<void> addItem(String householdId, String name) async {
    await _repo.addItem(householdId, name);
  }

  // Leggere la lista
  Future<List<ShoppingItem>> getShoppingList(String householdId) async {
    return await _repo.getList(householdId);
  }

  // Spuntare l'oggetto (Comprato / Da comprare)
  // Questa funzione riceve l'oggetto intero per sapere il suo stato attuale e dire al repository di invertirlo.
  Future<void> toggleItemStatus(ShoppingItem item) async {
    // Passiamo lo stato ATTUALE. Il repository penserà a mettere quello opposto.
    await _repo.toggleStatus(item.id, item.status); 
  }                                        

  // Cancellare dalla lista
  Future<void> deleteItem(String itemId) async {
    await _repo.deleteItem(itemId);
  }
}