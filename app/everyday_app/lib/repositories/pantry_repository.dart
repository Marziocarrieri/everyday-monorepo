import '../models/pantry_item.dart';
import 'supabase_client.dart';

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