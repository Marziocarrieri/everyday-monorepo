import '../models/pantry_item.dart';
import '../repositories/pantry_repository.dart';

class PantryService {
  final PantryRepository _repo = PantryRepository();

  // Aggiungi oggetto
  Future<void> addPantryItem({
    required String householdId,
    required String name,
    required int quantity,
    required String area, // 'FRIDGE', 'PANTRY', 'FREEZER'
    DateTime? expirationDate,
  }) async {
    
    // Creiamo la Mappa da dare al Repository.
    // Se c'è una data di scadenza, la trasformiamo in stringa , altrimenti lasciamo null.
    final Map<String, dynamic> itemData = {
      'household_id': householdId,
      'name': name,
      'quantity': quantity,
      'area': area,
      'expiration_date': expirationDate?.toIso8601String(), // Trasforma data in testo
    };

    await _repo.addItem(itemData);
  }

  // Visualizzazione degli oggetti
  Future<List<PantryItem>> getItemsByArea(String householdId, String area) async {
    return await _repo.getItemsByArea(householdId, area);
  }

  // Modifica della quantità
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      // Se la quantità diventa 0, tanto vale cancellare l'oggetto!
      await deleteItem(itemId);
    } else {
      await _repo.updateQuantity(itemId, newQuantity);
    }
  }

  // Rimozione oggetti
  Future<void> deleteItem(String itemId) async {
    await _repo.deleteItem(itemId);
  }
}