import 'package:flutter/foundation.dart';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet_activity.dart'; 


class PetActivitiesRepository {
  final Map<String, Map<String, dynamic>> _cachedActivitiesRowsById = {};
  List<PetActivity> _cachedActivities = const <PetActivity>[];

  String? _readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _readPetId(Map<String, dynamic> row) {
    return _readString(row['petId']) ?? _readString(row['pet_id']);
  }

  String _buildRowSignature(Map<String, dynamic> row) {
    final id = _readString(row['id']) ?? '-';
    final updatedAt = _readString(row['updated_at']) ??
        _readString(row['created_at']) ??
        _readString(row['date']) ??
        '-';
    final description = _readString(row['description']) ?? '-';
    final time = _readString(row['time']) ?? '-';
    final endTime = _readString(row['end_time']) ?? '-';
    return '$id|$updatedAt|$description|$time|$endTime';
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
  Future<List<PetActivity>> getActivities(String petId) async {
    try {
      debugPrint('ACTIVITY LOAD → petId: $petId');

      // We query the 'pets_activities' table
      final response = await supabase
          .from('pets_activities') 
          .select('*')
          .eq('petId', petId)
          .order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      for (final row in data) {
        debugPrint('LOADED PET ACTIVITY JSON: $row');
      }

      return data
          .map((json) => PetActivity.fromJson(json))
          .toList();
          
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      rethrow; 
    }
  }

  Stream<List<PetActivity>> watchPetActivities(String petId) async* {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      yield const <PetActivity>[];
      return;
    }

    String? lastSnapshotSignature;
    var previousRowSignaturesById = <String, String>{};

    await for (final rows in supabase
        .from('pets_activities')
        .stream(primaryKey: ['id'])
        .eq('petId', normalizedPetId)) {
      final nextRowsById = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final incoming = Map<String, dynamic>.from(row);
        final id = _readString(incoming['id']);
        if (id == null) {
          continue;
        }

        final previous = _cachedActivitiesRowsById[id];
        nextRowsById[id] = previous == null
            ? incoming
            : <String, dynamic>{...previous, ...incoming};
      }

      _cachedActivitiesRowsById
        ..clear()
        ..addAll(nextRowsById);

      final filteredRows = _cachedActivitiesRowsById.values
          .where((row) => _readPetId(row) == normalizedPetId)
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
            debugPrint('PET ACTIVITY REALTIME EVENT id=$id type=INSERT');
          }
          continue;
        }

        if (previousSignature != signature) {
          if (kDebugMode) {
            debugPrint('PET ACTIVITY REALTIME EVENT id=$id type=UPDATE');
          }
        }
      }

      final deletedIds = previousRowSignaturesById.keys
          .where((id) => !currentRowSignaturesById.containsKey(id));
      if (kDebugMode) {
        for (final id in deletedIds) {
          debugPrint('PET ACTIVITY REALTIME EVENT id=$id type=DELETE');
        }
      }

      previousRowSignaturesById = Map<String, String>.from(
        currentRowSignaturesById,
      );

      final snapshotSignature = _buildSnapshotSignature(filteredRows);
      final previousSnapshotSignature = lastSnapshotSignature;
      lastSnapshotSignature = snapshotSignature;
      if (kDebugMode && previousSnapshotSignature == snapshotSignature) {
        debugPrint(
          'PET ACTIVITY SNAPSHOT SIGNATURE unchanged=$snapshotSignature',
        );
      }

      final newList = filteredRows
          .map((row) {
            try {
              return PetActivity.fromJson(Map<String, dynamic>.from(row));
            } catch (error) {
              if (kDebugMode) {
                final rowId = _readString(row['id']) ?? '-';
                debugPrint('PET ACTIVITY ROW SKIPPED id=$rowId error=$error');
              }
              return null;
            }
          })
          .whereType<PetActivity>()
          .toList(growable: false);

      _cachedActivities = List<PetActivity>.from(newList);
      final emittedSnapshot = List<PetActivity>.unmodifiable(
        List<PetActivity>.from(_cachedActivities),
      );

      if (kDebugMode) {
        debugPrint(
          'PET ACTIVITY SNAPSHOT EMITTED length=${emittedSnapshot.length}',
        );
        print(
          'PET ACTIVITY STREAM EMIT '
          'identity=${identityHashCode(_cachedActivities)} '
          'length=${_cachedActivities.length}',
        );
      }

      yield emittedSnapshot;
    }
  }

  Stream<List<PetActivity>> watchActivities(String petId) {
    return watchPetActivities(petId);
  }

  /// Inserisce una nuova attività per un pet nella tabella 'pets_activities'
  Future<void> insertActivity({
    required String houseHoldId,
    required String petId,
    required String description,
    required DateTime date,
    required String time, // Formato "HH:mm:ss"
    String? endTime,      // Opzionale, formato "HH:mm:ss"
    String? notes,        // <-- AGGIUNTO
  }) async {
    try {
      debugPrint('SAVING ACTIVITY → petId: $petId');

      await supabase.from('pets_activities').insert({
        'houseHoldId': houseHoldId,
        'petId': petId,
        'description': description,
        'date': date.toIso8601String().split('T')[0], // Estrae solo YYYY-MM-DD
        'time': time,
        'end_time': endTime,
        'notes': notes, // <-- AGGIUNTO
      });

      debugPrint('ACTIVITY SAVED SUCCESSFULLY');
    } catch (e) {
      debugPrint('Error inserting pet activity: $e');
      rethrow;
    }
  }

  /// Elimina un'attività specifica dal database usando il suo ID
  Future<void> deleteActivity(String activityId) async {
    try {
      debugPrint('DELETING ACTIVITY → id: $activityId');

      // Interroga Supabase per cancellare la riga dove l'id corrisponde
      await supabase
          .from('pets_activities')
          .delete()
          .eq('id', activityId);

      debugPrint('ACTIVITY DELETED SUCCESSFULLY');
    } catch (e) {
      debugPrint('Error deleting pet activity: $e');
      rethrow;
    }
  }
}