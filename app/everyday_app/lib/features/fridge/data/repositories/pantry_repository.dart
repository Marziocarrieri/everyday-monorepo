import '../models/pantry_item.dart';
import '../../../../shared/repositories/supabase_client.dart';

class PantryRepository {

  // Aggiungi cibo
  Future<void> addItem(Map<String, dynamic> itemData) async {
    await supabase.from('pantry_item').insert(itemData);
  }

  // Scarica cibo diviso per area (es. dammi solo cose in FRIDGE)
  Future<List<PantryItem>> getItemsByArea(String householdId, String area) async {
    final response = await supabase
        .from('pantry_item')
        .select()
        .eq('household_id', householdId)
        .eq('area', area); // Filtra per area ('FRIDGE', 'PANTRY'...)

    return (response as List)
        .map((json) => PantryItem.fromJson(json))
        .toList();
  }

  Stream<List<PantryItem>> watchPantryItems(String householdId) {
    final cachedRowsById = <String, Map<String, dynamic>>{};

    return supabase
        .from('pantry_item')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final nextRowsById = <String, Map<String, dynamic>>{};

          for (final row in rows) {
            final incoming = Map<String, dynamic>.from(row);
            final id = incoming['id']?.toString();
            if (id == null || id.isEmpty) {
              continue;
            }

            final previous = cachedRowsById[id];
            nextRowsById[id] = previous == null
                ? incoming
                : <String, dynamic>{...previous, ...incoming};
          }

          cachedRowsById
            ..clear()
            ..addAll(nextRowsById);

          final filteredRows = cachedRowsById.values
              .where((row) => row['household_id'] == householdId)
              .toList();

          return filteredRows
              .map((row) {
                try {
                  return PantryItem.fromJson(row);
                } catch (_) {
                  return null;
                }
              })
              .whereType<PantryItem>()
              .toList();
        });
  }

  // Aggiorna quantità (es. ho bevuto una bottiglia d'acqua)
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    await supabase
        .from('pantry_item')
        .update({'quantity': newQuantity})
        .eq('id', itemId);
  }

  // Cancella oggetto (finito tutto)
  Future<void> deleteItem(String itemId) async {
    await supabase.from('pantry_item').delete().eq('id', itemId);
  }
}