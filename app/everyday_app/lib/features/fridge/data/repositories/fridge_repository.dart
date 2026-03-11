import 'package:flutter/foundation.dart';

import '../models/area_type.dart';
import '../models/fridge_item.dart';
import '../../../../shared/repositories/supabase_client.dart';

class FridgeRepository {
  Future<List<FridgeItem>> getItems(String householdId, AreaType area) async {
    print('FRIDGE LOAD → household: $householdId');

    final response = await supabase
        .from('pantry_item')
        .select('*')
        .eq('household_id', householdId)
        .eq('area', area.dbValue)
        .order('created_at', ascending: false);

    for (final row in List<Map<String, dynamic>>.from(response)) {
      debugPrint('LOADED ITEM JSON: $row');
    }

    return List<Map<String, dynamic>>.from(response)
        .map(FridgeItem.fromJson)
        .toList();
  }

  Stream<List<FridgeItem>> watchPantryItems(String householdId) {
    return supabase
        .from('pantry_item')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filteredRows = rows
              .map((row) => Map<String, dynamic>.from(row))
              .where((row) => row['household_id'] == householdId)
              .toList();

          return filteredRows.map(FridgeItem.fromJson).toList();
        });
  }

  Future<void> addItem({
    required String householdId,
    required String name,
    required AreaType area,
    int? quantity,
    int? weight,
    String? unit,
    DateTime? expirationDate,
  }) async {
    debugPrint('INSERT PAYLOAD: ${{
      'household_id': householdId,
      'name': name,
      'area': area.dbValue,
      'quantity': quantity,
      'weight': weight,
      'unit': unit,
      'expiration_date': expirationDate,
    }}');

    await supabase.from('pantry_item').insert({
      'household_id': householdId,
      'name': name,
      'area': area.dbValue,
      'quantity': quantity,
      'weight': weight,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String(),
    });
  }

  Future<void> deleteItem(String itemId) async {
    await supabase.from('pantry_item').delete().eq('id', itemId);
  }

  Future<void> updateItem(FridgeItem updatedItem) async {
    final payload = {
      'name': updatedItem.name,
      'quantity': updatedItem.quantity,
      'weight': updatedItem.weight,
      'expiration_date': updatedItem.expirationDate?.toIso8601String(),
    };

    debugPrint('UPDATE PAYLOAD: $payload');

    await supabase
        .from('pantry_item')
        .update(payload)
        .eq('id', updatedItem.id);
  }
}
