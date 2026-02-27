import '../models/fridge_item.dart';
import 'supabase_client.dart';

class FridgeRepository {
  Future<List<FridgeItem>> getItems(String householdId) async {
    final response = await supabase
        .from('fridge_items')
        .select('*')
        .eq('household_id', householdId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map(FridgeItem.fromJson)
        .toList();
  }

  Future<void> addItem({
    required String householdId,
    required String name,
  }) async {
    await supabase.from('fridge_items').insert({
      'household_id': householdId,
      'name': name,
    });
  }

  Future<void> deleteItem(String itemId) async {
    await supabase.from('fridge_items').delete().eq('id', itemId);
  }
}
