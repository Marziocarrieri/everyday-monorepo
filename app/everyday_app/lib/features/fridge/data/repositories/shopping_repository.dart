import '../models/shopping_item.dart';
import '../../../../shared/repositories/supabase_client.dart';

class ShoppingRepository {
  Future<void> addItem(
    String householdId,
    String name, {
    int quantity = 1,
  }) async {
    await supabase.from('shopping_item').insert({
      'household_id': householdId,
      'name': name,
      'status': 'PENDING', // Di default è da comprare
      'quantity': quantity,
    });
  }

  Future<List<ShoppingItem>> getList(String householdId) async {
    final response = await supabase
        .from('shopping_item')
        .select()
        .eq('household_id', householdId)
        .order('created_at');

    return (response as List)
        .map((json) => ShoppingItem.fromJson(json))
        .toList();
  }

  Stream<List<ShoppingItem>> watchShoppingItems(String householdId) {
    return supabase
        .from('shopping_item')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filteredRows = rows
              .map((row) => Map<String, dynamic>.from(row))
              .where((row) => row['household_id'] == householdId)
              .toList();

          return filteredRows.map(ShoppingItem.fromJson).toList();
        });
  }

  // Cambia stato (da PENDING a BOUGHT)
  Future<void> toggleStatus(String itemId, String currentStatus) async {
    final newStatus = currentStatus == 'PENDING' ? 'BOUGHT' : 'PENDING';

    await supabase
        .from('shopping_item')
        .update({'status': newStatus})
        .eq('id', itemId);
  }

  // Cancella dalla lista
  Future<void> deleteItem(String itemId) async {
    await supabase.from('shopping_item').delete().eq('id', itemId);
  }

  Future<void> updateItem(ShoppingItem item) async {
    await supabase
        .from('shopping_item')
        .update({
          'name': item.name,
          'quantity': item.quantity,
          'status': item.status,
        })
        .eq('id', item.id);
  }
}
