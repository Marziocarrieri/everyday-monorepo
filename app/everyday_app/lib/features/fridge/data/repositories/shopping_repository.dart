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

  Stream<List<ShoppingItem>> watchShoppingItems(String householdId) async* {
    String? lastSnapshotSignature;
    var previousRowSignaturesById = <String, String>{};

    await for (final rows
        in supabase.from('shopping_item').stream(primaryKey: ['id'])) {
      final nextRowsById = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final incoming = Map<String, dynamic>.from(row);
        final id = _readString(incoming['id']);
        if (id == null) {
          continue;
        }

        final previous = _cachedShoppingRowsById[id];
        nextRowsById[id] = previous == null
            ? incoming
            : <String, dynamic>{...previous, ...incoming};
      }

      _cachedShoppingRowsById
        ..clear()
        ..addAll(nextRowsById);

      final filteredRows = _cachedShoppingRowsById.values
          .where((row) => _readString(row['household_id']) == householdId)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final currentRowSignaturesById = <String, String>{};
      for (final row in filteredRows) {
        final id = _readString(row['id']);
        if (id == null) {
          continue;
        }

        final signature = _buildRowSignature(row);
        currentRowSignaturesById[id] = signature;

        final previousSignature = previousRowSignaturesById[id];
        if (previousSignature != null && previousSignature != signature) {
          if (kDebugMode) {
            debugPrint('UTILITY UPDATE EVENT id=$id');
          }
        }
      }
      previousRowSignaturesById = Map<String, String>.from(
        currentRowSignaturesById,
      );

      final snapshotSignature = _buildSnapshotSignature(filteredRows);
      if (snapshotSignature == lastSnapshotSignature) {
        continue;
      }
      lastSnapshotSignature = snapshotSignature;

      final newList = filteredRows
          .map((row) {
            try {
              return ShoppingItem.fromJson(Map<String, dynamic>.from(row));
            } catch (_) {
              return null;
            }
          })
          .whereType<ShoppingItem>()
          .toList(growable: false);

      if (kDebugMode) {
        debugPrint('UTILITY SNAPSHOT EMITTED length=${newList.length}');
      }

      yield List<ShoppingItem>.from(newList);
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
}
