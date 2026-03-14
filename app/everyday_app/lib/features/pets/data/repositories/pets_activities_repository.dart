import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
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

  Stream<List<PetActivity>> watchPetActivities(String petId) {
    final normalizedPetId = petId.trim();
    if (normalizedPetId.isEmpty) {
      return Stream<List<PetActivity>>.value(const <PetActivity>[]);
    }

    late final StreamController<List<PetActivity>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? snapshotSubscription;
    RealtimeChannel? deleteRealtimeChannel;
    var disposed = false;
    String? lastSnapshotSignature;

    void emitFromCache({required String source}) {
      if (disposed || controller.isClosed) {
        return;
      }

      final filteredRows = _cachedActivitiesRowsById.values
          .where((row) => _readPetId(row) == normalizedPetId)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final snapshotSignature = _buildSnapshotSignature(filteredRows);
      if (kDebugMode && snapshotSignature == lastSnapshotSignature) {
        debugPrint(
          'PET ACTIVITY SNAPSHOT SIGNATURE unchanged=$snapshotSignature',
        );
      }
      lastSnapshotSignature = snapshotSignature;

      final nextActivities = filteredRows
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

      final previousLength = _cachedActivities.length;
      _cachedActivities = List<PetActivity>.from(nextActivities);
      final emittedSnapshot = List<PetActivity>.unmodifiable(
        List<PetActivity>.from(_cachedActivities),
      );

      if (kDebugMode) {
        if (previousLength != _cachedActivities.length) {
          debugPrint(
            'PET ACTIVITY CACHE LENGTH CHANGED source=$source before=$previousLength after=${_cachedActivities.length}',
          );
        }
        debugPrint(
          'PET ACTIVITY SNAPSHOT EMITTED source=$source length=${emittedSnapshot.length}',
        );
        print(
          'PET ACTIVITY STREAM EMIT '
          'identity=${identityHashCode(_cachedActivities)} '
          'length=${_cachedActivities.length}',
        );
      }

      controller.add(emittedSnapshot);
    }

    Future<void> disposeWatch() async {
      if (disposed) {
        return;
      }

      disposed = true;
      await snapshotSubscription?.cancel();
      if (deleteRealtimeChannel != null) {
        await supabase.removeChannel(deleteRealtimeChannel!);
      }
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<List<PetActivity>>.broadcast(
      onListen: () {
        _cachedActivitiesRowsById.clear();
        _cachedActivities = const <PetActivity>[];
        lastSnapshotSignature = null;

        snapshotSubscription = supabase
            .from('pets_activities')
            .stream(primaryKey: ['id'])
            .eq('petId', normalizedPetId)
            .listen((rows) {
              final nextRowsById = <String, Map<String, dynamic>>{};
              for (final row in rows) {
                final incoming = Map<String, dynamic>.from(row);
                final id = _readString(incoming['id']);
                if (id == null) {
                  continue;
                }
                nextRowsById[id] = incoming;
              }

              _cachedActivitiesRowsById
                ..clear()
                ..addAll(nextRowsById);

              emitFromCache(source: 'pet_activities_snapshot_stream');
            }, onError: (Object error, StackTrace stackTrace) {
              if (!disposed && !controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            });

        deleteRealtimeChannel = supabase
            .channel('schema-db-changes:pet-activities-delete:$normalizedPetId')
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'pets_activities',
              callback: (payload) {
                if (payload.eventType != PostgresChangeEvent.delete) {
                  return;
                }

                final deletedId = _readString(payload.oldRecord['id']);
                if (deletedId == null) {
                  return;
                }

                final deletedPetId =
                    _readString(payload.oldRecord['petId']) ??
                    _readString(payload.oldRecord['pet_id']);
                if (deletedPetId != null && deletedPetId != normalizedPetId) {
                  return;
                }

                if (kDebugMode) {
                  debugPrint(
                    'PET ACTIVITY REALTIME DELETE RECEIVED id=$deletedId',
                  );
                }

                final existed = _cachedActivitiesRowsById.remove(deletedId) != null;
                if (!existed) {
                  return;
                }

                _cachedActivities = List<PetActivity>.from(_cachedActivities)
                  ..removeWhere((activity) => activity.id == deletedId);

                emitFromCache(source: 'pet_activities_delete_realtime');
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (controller.hasListener) {
          return;
        }
        await disposeWatch();
      },
    );

    return controller.stream;
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