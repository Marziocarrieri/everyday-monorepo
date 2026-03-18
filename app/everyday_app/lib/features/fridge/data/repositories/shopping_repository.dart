import 'package:flutter/foundation.dart';

import '../models/shopping_item.dart';
import '../../../../shared/repositories/supabase_client.dart';

class ShoppingRepository {
  final Map<String, Map<String, dynamic>> _cachedShoppingRowsById = {};

  String? _readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _buildRowSignature(Map<String, dynamic> row) {
    final id = _readString(row['id']) ?? '-';
    final updatedAt = _readString(row['updated_at']) ??
        _readString(row['created_at']) ??
        '-';
    final name = _readString(row['name']) ?? '-';
    final quantity = _readString(row['quantity']) ?? '-';
    final status = _readString(row['status']) ?? '-';
    return '$id|$updatedAt|$name|$quantity|$status';
  }

  String _buildSnapshotSignature(List<Map<String, dynamic>> rows) {
    final sorted = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false)
      ..sort((left, right) {
        final leftId = _readString(left['id']) ?? '';
        final rightId = _readString(right['id']) ?? '';
        return leftId.compareTo(rightId);
      });

    final content = sorted.map(_buildRowSignature).join('#');
    return '${rows.length}:$content';
  }

  Future<void> addItem(
    String householdId,
    String name, {
    int quantity = 1,
    int? recommendedItemId,
  }) async {
    await supabase.from('shopping_item').insert({
      'household_id': householdId,
      'name': name,
      'status': 'PENDING', // Di default è da comprare
      'quantity': quantity,
      'recommended_item_id': recommendedItemId,
    });
  }

  Future<List<ShoppingItem>> getList(String householdId) async {
    final response = await supabase
        .from('shopping_item')
        .select('*,recommended_item:recommended_item_id (*)')
        .eq('household_id', householdId)
        .order('created_at');

    return (response as List)
        .map((json) => ShoppingItem.fromJson(json))
        .toList();
  }

  Stream<List<ShoppingItem>> watchShoppingItems(String householdId) async* {
    // Keeping track of signatures to avoid unnecessary UI rebuilds
    String? lastSnapshotSignature;

    await for (final rows in supabase.from('shopping_item').stream(primaryKey: ['id'])) {
      
      // 1. Filter rows for the current household
      // Use .toString() on household_id to ensure String comparison
      final filteredRows = rows.where((row) {
        return row['household_id']?.toString() == householdId;
      }).toList();

      // 2. Extract unique Recommended Item IDs (as Integers)
      final recommendedIds = filteredRows
          .map((row) => row['recommended_item_id'])
          .where((id) => id != null)
          .map((id) => (id as num).toInt()) // The "Fix" for the type cast error
          .toSet()
          .toList();

      // 3. Fetch details for these recommendations from Supabase
      Map<int, Map<String, dynamic>> recommendedDataMap = {};
      
      if (recommendedIds.isNotEmpty) {
        try {
          final recItems = await supabase
              .from('recommended_item')
              .select()
              .inFilter('id', recommendedIds);
          
          for (var item in recItems) {
            final int id = (item['id'] as num).toInt();
            recommendedDataMap[id] = Map<String, dynamic>.from(item);
          }
        } catch (e) {
          debugPrint('Error fetching recommendations: $e');
        }
      }

      // 4. Stitch the data together into ShoppingItem objects
      final newList = filteredRows.map((row) {
        try {
          final rowData = Map<String, dynamic>.from(row);
          final dynamic rawRecId = rowData['recommended_item_id'];

          if (rawRecId != null) {
            final int recId = (rawRecId as num).toInt();
            // Inject the nested object so ShoppingItem.fromJson works
            rowData['recommended_item'] = recommendedDataMap[recId];
          } else {
            rowData['recommended_item'] = null;
          }

          return ShoppingItem.fromJson(rowData);
        } catch (e) {
          debugPrint('Error parsing item: $e');
          return null;
        }
      }).whereType<ShoppingItem>().toList();

      // 5. Build snapshot signature and yield list
      final snapshotSignature = _buildSnapshotSignature(filteredRows);
      if (snapshotSignature != lastSnapshotSignature) {
        lastSnapshotSignature = snapshotSignature;
        yield newList;
      }
    }
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
    final payload = <String, dynamic>{};
    final cachedRow = _cachedShoppingRowsById[item.id];

    final normalizedName = item.name.trim();
    final previousName = _readString(cachedRow?['name']);
    if (normalizedName.isNotEmpty &&
        (cachedRow == null || previousName != normalizedName)) {
      payload['name'] = normalizedName;
    }

    final previousQuantity = _readInt(cachedRow?['quantity']);
    if (item.quantity > 0 &&
        (cachedRow == null || previousQuantity != item.quantity)) {
      payload['quantity'] = item.quantity;
    }

    final normalizedStatus = item.status.trim();
    final previousStatus = _readString(cachedRow?['status']);
    if (normalizedStatus.isNotEmpty &&
        (cachedRow == null || previousStatus != normalizedStatus)) {
      payload['status'] = normalizedStatus;
    }

    if (payload.isEmpty) {
      debugPrint('UTILITY UPDATE SKIPPED id=${item.id} reason=no_changed_fields');
      return;
    }

    await supabase
        .from('shopping_item')
        .update(payload)
        .eq('id', item.id);
  }

  // --- NUOVI METODI PER LO STORICO ---
  Future<void> moveToHistory(String itemId) async {
    await supabase
        .from('shopping_item')
        .update({'status': 'BOUGHT'})
        .eq('id', itemId);
  }

  Future<void> restoreItem(String itemId) async {
    await supabase
        .from('shopping_item')
        .update({'status': 'PENDING'}) // Lo fa tornare da comprare
        .eq('id', itemId);
  }
}
