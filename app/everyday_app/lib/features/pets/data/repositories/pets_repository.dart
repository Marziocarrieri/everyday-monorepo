import 'package:flutter/foundation.dart';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet.dart'; 

class PetRepository {
  final Map<String, Map<String, dynamic>> _cachedPetsRowsById = {};

  String? _readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String _buildRowSignature(Map<String, dynamic> row) {
    final id = _readString(row['id']) ?? '-';
    final updatedAt = _readString(row['updated_at']) ??
        _readString(row['created_at']) ??
        '-';
    final name = _readString(row['name']) ?? '-';
    final species = _readString(row['species']) ?? '-';
    return '$id|$updatedAt|$name|$species';
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
  /// Fetches all pets for a specific household ID.
  /// Maps the database response to the Pet model.
  Future<List<Pet>> getPets(String householdId) async {
    try {
      debugPrint('PETS LOAD → household: $householdId');

      // We query the 'pets' table
      final response = await supabase
          .from('pets') 
          .select('*')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED PET JSON: $row');
      }

      return data
          .map((json) => Pet.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      rethrow; 
    }
  }

  Stream<List<Pet>> watchPets(String householdId) async* {
    String? lastSnapshotSignature;
    var previousRowSignaturesById = <String, String>{};

    await for (final rows in supabase.from('pets').stream(primaryKey: ['id'])) {
      final nextRowsById = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final incoming = Map<String, dynamic>.from(row);
        final id = _readString(incoming['id']);
        if (id == null) {
          continue;
        }

        final previous = _cachedPetsRowsById[id];
        nextRowsById[id] = previous == null
            ? incoming
            : <String, dynamic>{...previous, ...incoming};
      }

      _cachedPetsRowsById
        ..clear()
        ..addAll(nextRowsById);

      final filteredRows = _cachedPetsRowsById.values
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
        if (previousSignature == null) {
          if (kDebugMode) {
            debugPrint('PET REALTIME EVENT type=INSERT id=$id');
          }
          continue;
        }

        if (previousSignature != signature) {
          if (kDebugMode) {
            debugPrint('PET REALTIME EVENT type=UPDATE id=$id');
          }
        }
      }

      final deletedIds = previousRowSignaturesById.keys
          .where((id) => !currentRowSignaturesById.containsKey(id));
      if (kDebugMode) {
        for (final id in deletedIds) {
          debugPrint('PET REALTIME EVENT type=DELETE id=$id');
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
              return Pet.fromJson(Map<String, dynamic>.from(row));
            } catch (error) {
              if (kDebugMode) {
                final rowId = _readString(row['id']) ?? '-';
                debugPrint('PET ROW SKIPPED id=$rowId error=$error');
              }
              return null;
            }
          })
          .whereType<Pet>()
          .toList(growable: false);

      if (kDebugMode) {
        debugPrint('PET SNAPSHOT EMITTED length=${newList.length}');
      }

      yield List<Pet>.from(newList);
    }
  }

  /// Crea un nuovo Pet
  Future<void> createPet({
    required String name,
    required String species,
    required String householdId,
  }) async {
    try {
      await supabase.from('pets').insert({
        'name': name,
        'species': species,
        'household_id': householdId,
      });
      debugPrint('PET CREATED: $name');
    } catch (e) {
      debugPrint('Error creating pet: $e');
      rethrow;
    }
  }

  /// Elimina un Pet specifico dal database usando il suo ID
  Future<void> deletePet(String petId) async {
    try {
      debugPrint('DELETING PET → id: $petId');

      await supabase
          .from('pets')
          .delete()
          .eq('id', petId);

      debugPrint('PET DELETED SUCCESSFULLY');
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      rethrow;
    }
  }
}