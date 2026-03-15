import 'package:flutter/foundation.dart';

import '../models/area_type.dart';
import '../models/fridge_item.dart';
import '../../../../shared/repositories/supabase_client.dart';

class FridgeRepository {
  final Map<String, Map<String, dynamic>> _cachedPantryRowsById = {};

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
        _readString(row['expiration_date']) ??
        '-';
    final name = _readString(row['name']) ?? '-';
    final quantity = _readString(row['quantity']) ?? '-';
    final weight = _readString(row['weight']) ?? '-';
    final expiration = _readString(row['expiration_date']) ?? '-';
    return '$id|$updatedAt|$name|$quantity|$weight|$expiration';
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

  Future<List<FridgeItem>> getItems(String householdId, AreaType area) async {
    debugPrint('FRIDGE LOAD → household: $householdId');

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

  Stream<List<FridgeItem>> watchPantryItems(String householdId) async* {
    String? lastSnapshotSignature;
    var previousRowSignaturesById = <String, String>{};

    await for (final rows
        in supabase.from('pantry_item').stream(primaryKey: ['id'])) {
      final nextRowsById = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final incoming = Map<String, dynamic>.from(row);
        final id = _readString(incoming['id']);
        if (id == null) {
          continue;
        }

        final previous = _cachedPantryRowsById[id];
        nextRowsById[id] = previous == null
            ? incoming
            : <String, dynamic>{...previous, ...incoming};
      }

      _cachedPantryRowsById
        ..clear()
        ..addAll(nextRowsById);

      final filteredRows = _cachedPantryRowsById.values
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
              return FridgeItem.fromJson(Map<String, dynamic>.from(row));
            } catch (error) {
              debugPrint('Skipping invalid pantry stream row: $error');
              return null;
            }
          })
          .whereType<FridgeItem>()
          .toList(); // <-- Rimosso growable: false per poterla ordinare!

      // --- LOGICA DI ORDINAMENTO (SORTING) ---
      newList.sort((a, b) {
        // Se entrambi non hanno la data, mantieni l'ordine attuale
        if (a.expirationDate == null && b.expirationDate == null) return 0;
        // Se 'a' non ha la data, mettilo dopo 'b'
        if (a.expirationDate == null) return 1;
        // Se 'b' non ha la data, metti 'a' prima di 'b'
        if (b.expirationDate == null) return -1;
        
        // Entrambi hanno la data: ordina in ordine crescente (le date più vecchie prima)
        return a.expirationDate!.compareTo(b.expirationDate!);
      });

      if (kDebugMode) {
        debugPrint('UTILITY SNAPSHOT EMITTED length=${newList.length}');
      }

      yield List<FridgeItem>.from(newList);
    }
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
    final payload = <String, dynamic>{};
    final cachedRow = _cachedPantryRowsById[updatedItem.id];

    final normalizedName = updatedItem.name.trim();
    final previousName = _readString(cachedRow?['name']);
    if (normalizedName.isNotEmpty &&
        (cachedRow == null || previousName != normalizedName)) {
      payload['name'] = normalizedName;
    }

    if (updatedItem.quantity != null) {
      final previousQuantity = _readInt(cachedRow?['quantity']);
      if (cachedRow == null || previousQuantity != updatedItem.quantity) {
        payload['quantity'] = updatedItem.quantity;
      }
    }

    if (updatedItem.weight != null) {
      final previousWeight = _readInt(cachedRow?['weight']);
      if (cachedRow == null || previousWeight != updatedItem.weight) {
        payload['weight'] = updatedItem.weight;
      }
    }

    if (updatedItem.expirationDate != null) {
      final nextExpirationIso = updatedItem.expirationDate!.toIso8601String();
      final previousExpirationIso = _readString(cachedRow?['expiration_date']);
      if (cachedRow == null || previousExpirationIso != nextExpirationIso) {
        payload['expiration_date'] = nextExpirationIso;
      }
    }

    if (payload.isEmpty) {
      debugPrint(
        'UTILITY UPDATE SKIPPED id=${updatedItem.id} reason=no_changed_fields',
      );
      return;
    }

    debugPrint('UPDATE PAYLOAD: $payload');

    await supabase
        .from('pantry_item')
        .update(payload)
        .eq('id', updatedItem.id);
  }
}