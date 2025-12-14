import '../models/shopping_item.dart';
import 'supabase_client.dart';

class ShoppingRepository {

  Future<void> addItem(String householdId, String name) async {
    await supabase.from('shopping_item').insert({
      'household_id': householdId,
      'name': name,
      'status': 'PENDING', // Di default è da comprare
      'quantity': 1,
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
}