import 'package:flutter/foundation.dart';

import 'supabase_client.dart';
import 'package:everyday_app/shared/models/diet_document.dart';

class DietRepository {
  // --- MODIFICA 1: Aggiunto il parametro userId ---
  Stream<DietDocument?> watchDiet(String householdId, String userId) async* {
    final cachedRowsById = <String, Map<String, dynamic>>{};
    String? lastSnapshotSignature;

    await for (final rows
        in supabase.from('diet_document').stream(primaryKey: ['id'])) {
      
      final previousHouseholdIds = cachedRowsById.values
          // --- MODIFICA 2: Filtro per household_id E user_id ---
          .where((row) => _readString(row['household_id']) == householdId && _readString(row['user_id']) == userId)
          .map((row) => _readString(row['id']))
          .whereType<String>()
          .toSet();

      final nextRowsById = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final incoming = Map<String, dynamic>.from(row);
        final id = _readString(incoming['id']);
        if (id == null) {
          continue;
        }

        final previous = cachedRowsById[id];
        nextRowsById[id] = previous == null
            ? incoming
            : <String, dynamic>{...previous, ...incoming};
      }

      final nextHouseholdIds = nextRowsById.values
          // --- MODIFICA 3: Filtro per household_id E user_id ---
          .where((row) => _readString(row['household_id']) == householdId && _readString(row['user_id']) == userId)
          .map((row) => _readString(row['id']))
          .whereType<String>()
          .toSet();

      final deletedIds = previousHouseholdIds.difference(nextHouseholdIds);
      if (kDebugMode) {
        for (final deletedId in deletedIds) {
          debugPrint('DIET DELETE EVENT RECEIVED id=$deletedId');
        }
      }

      cachedRowsById
        ..clear()
        ..addAll(nextRowsById);

      final householdRows = cachedRowsById.values
          // --- MODIFICA 4: Filtro per household_id E user_id ---
          .where((row) => _readString(row['household_id']) == householdId && _readString(row['user_id']) == userId)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      householdRows.sort((left, right) {
        final leftDate = DateTime.tryParse(
          _readString(left['uploaded_at']) ?? '',
        );
        final rightDate = DateTime.tryParse(
          _readString(right['uploaded_at']) ?? '',
        );

        final normalizedLeft = leftDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final normalizedRight =
            rightDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return normalizedRight.compareTo(normalizedLeft);
      });

      final snapshotSignature = _buildSnapshotSignature(householdRows);
      if (snapshotSignature == lastSnapshotSignature) {
        continue;
      }
      lastSnapshotSignature = snapshotSignature;

      if (kDebugMode) {
        debugPrint('DIET SNAPSHOT EMITTED length=${householdRows.length}');
      }

      if (householdRows.isEmpty) {
        yield null;
        continue;
      }

      DietDocument? latestDiet;
      for (final row in householdRows) {
        try {
          latestDiet = DietDocument.fromJson(Map<String, dynamic>.from(row));
          break;
        } catch (error) {
          if (kDebugMode) {
            final rowId = _readString(row['id']) ?? '-';
            debugPrint(
              'DIET ROW SKIPPED id=$rowId error=$error',
            );
          }
        }
      }

      yield latestDiet;
    }
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String _buildSnapshotSignature(List<Map<String, dynamic>> rows) {
    final sortedRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false)
      ..sort((left, right) {
        final leftId = _readString(left['id']) ?? '';
        final rightId = _readString(right['id']) ?? '';
        return leftId.compareTo(rightId);
      });

    final rowsSignature = sortedRows
        .map((row) {
          final id = _readString(row['id']) ?? '-';
          final uploadedAt = _readString(row['uploaded_at']) ?? '-';
          final url = _readString(row['url']) ?? '-';
          return '$id|$uploadedAt|$url';
        })
        .join('#');

    return '${rows.length}:$rowsSignature';
  }

  Future<void> insertDietDocument({
    required String householdId,
    required String userId,
    required String url,
  }) async {
    await supabase.from('diet_document').insert({
      'household_id': householdId,
      'user_id': userId,
      'url': url,
    });
  }

  Future<void> deleteDietDocument({
    required String docId,
    required String householdId,
    required String userId,
  }) async {
    await supabase
        .from('diet_document')
        .delete()
        .eq('id', docId)
        .eq('household_id', householdId)
        .eq('user_id', userId);
  }
}