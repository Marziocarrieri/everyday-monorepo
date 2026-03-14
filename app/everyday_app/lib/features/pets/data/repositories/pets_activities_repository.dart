import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
import 'dart:convert';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet_activity.dart'; 


class PetActivitiesRepository {
  String? _readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _readPetId(Map<String, dynamic> row) {
    return _readString(row['petId']) ?? _readString(row['pet_id']);
  }

  String? _normalizeNullableString(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String? _extractMissingColumnName(Object error) {
    final message = error.toString();
    final patterns = <RegExp>[
      RegExp(
        r"Could not find the '([A-Za-z0-9_]+)' column",
        caseSensitive: false,
      ),
      RegExp(
        r"column\s+'([A-Za-z0-9_]+)'",
        caseSensitive: false,
      ),
      RegExp(
        r'column\s+"([A-Za-z0-9_]+)"',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      final column = match?.group(1);
      if (column != null && column.isNotEmpty) {
        return column;
      }
    }

    return null;
  }

  Future<void> _insertWithMissingColumnFallback(
    Map<String, dynamic> payload,
  ) async {
    final candidatePayload = Map<String, dynamic>.from(payload);
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await supabase.from('pets_activities').insert(candidatePayload);
        return;
      } catch (error) {
        final missingColumn = _extractMissingColumnName(error);
        if (missingColumn == null || !candidatePayload.containsKey(missingColumn)) {
          rethrow;
        }

        if (kDebugMode) {
          debugPrint(
            'PET ACTIVITY INSERT RETRY remove_missing_column=$missingColumn',
          );
        }

        candidatePayload.remove(missingColumn);
      }
    }

    throw Exception('Pets activity insert failed: missing required columns');
  }

  Future<void> _ensurePetBelongsToHousehold({
    required String petId,
    required String householdId,
  }) async {
    final row = await supabase
        .from('pets')
        .select('id, household_id')
        .eq('id', petId)
        .maybeSingle();

    if (row == null) {
      throw Exception('Cannot create activity for missing pet');
    }

    final mapped = Map<String, dynamic>.from(row);
    final petHouseholdId = _readString(mapped['household_id']);
    if (petHouseholdId != null && petHouseholdId != householdId) {
      throw Exception('Pet does not belong to active household');
    }
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
    var started = false;
    var activeListeners = 0;
    final stateById = <String, Map<String, dynamic>>{};
    final deletedIds = <String>{};
    var lastLength = 0;

    void upsertStateRow(
      Map<String, dynamic> row, {
      required String source,
    }) {
      final id = _readString(row['id']);
      if (id == null) {
        return;
      }

      if (deletedIds.contains(id)) {
        if (kDebugMode) {
          debugPrint(
            'PET ACTIVITY UPSERT SKIPPED TOMBSTONE source=$source id=$id',
          );
        }
        return;
      }

      final previous = stateById[id];
      stateById[id] = previous == null
          ? Map<String, dynamic>.from(row)
          : <String, dynamic>{...previous, ...row};

      if (kDebugMode) {
        final type = previous == null ? 'INSERT' : 'UPDATE';
        debugPrint(
          'PET ACTIVITY REALTIME EVENT id=$id type=$type source=$source',
        );
      }
    }

    void emitFromCache({required String source}) {
      if (disposed || controller.isClosed) {
        return;
      }

      final filteredRows = stateById.values
          .where((row) => _readPetId(row) == normalizedPetId)
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

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
          .toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));

      final emittedSnapshot = List<PetActivity>.unmodifiable(
        List<PetActivity>.from(nextActivities),
      );

      if (kDebugMode) {
        if (lastLength != emittedSnapshot.length) {
          debugPrint(
            'PET ACTIVITY CACHE LENGTH CHANGED source=$source before=$lastLength after=${emittedSnapshot.length}',
          );
        }
        lastLength = emittedSnapshot.length;

        debugPrint(
          'PET ACTIVITY SNAPSHOT EMITTED source=$source length=${emittedSnapshot.length}',
        );
        print(
          'PET ACTIVITY STREAM EMIT '
          'identity=${identityHashCode(emittedSnapshot)} '
          'length=${emittedSnapshot.length}',
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
        activeListeners++;
        if (started) {
          return;
        }

        started = true;
        stateById.clear();
        deletedIds.clear();
        lastLength = 0;

        emitFromCache(source: 'watch_start');

        snapshotSubscription = supabase
            .from('pets_activities')
            .stream(primaryKey: ['id'])
            .eq('petId', normalizedPetId)
            .listen((rows) {
              for (final row in rows) {
                final incoming = Map<String, dynamic>.from(row);
                upsertStateRow(
                  incoming,
                  source: 'pet_activities_snapshot_stream',
                );
              }

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

                deletedIds.add(deletedId);
                stateById.remove(deletedId);

                emitFromCache(source: 'pet_activities_delete_realtime');
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (activeListeners > 0) {
          activeListeners--;
        }

        if (activeListeners > 0) {
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
    required String householdId,
    required String petId,
    required DateTime date,
    String? description,
    String? startTime,
    String? endTime,
    String? notes,
    String? memberId,
    String? createdBy,
  }) async {
    try {
      final normalizedHouseholdId = householdId.trim();
      final normalizedPetId = petId.trim();
      if (normalizedHouseholdId.isEmpty || normalizedPetId.isEmpty) {
        throw Exception('Missing household_id or pet_id');
      }

      final normalizedDescription = _normalizeNullableString(description);
      final normalizedStartTime = _normalizeNullableString(startTime);
      final normalizedEndTime = _normalizeNullableString(endTime);
      final normalizedNotes = _normalizeNullableString(notes);
      final normalizedMemberId = _normalizeNullableString(memberId);
      final normalizedCreatedBy =
          _normalizeNullableString(createdBy) ??
          _normalizeNullableString(supabase.auth.currentUser?.id);
      final normalizedDate = date.toIso8601String().split('T')[0];

      await _ensurePetBelongsToHousehold(
        petId: normalizedPetId,
        householdId: normalizedHouseholdId,
      );

      final debugPayload = <String, dynamic>{
        'pet_id': normalizedPetId,
        'household_id': normalizedHouseholdId,
        'member_id': normalizedMemberId,
        'created_by': normalizedCreatedBy,
        'date': normalizedDate,
        'start': normalizedStartTime,
        'end': normalizedEndTime,
      };
      if (kDebugMode) {
        debugPrint('PET ACTIVITY INSERT PAYLOAD ${jsonEncode(debugPayload)}');
      }

      final payload = <String, dynamic>{
        'petId': normalizedPetId,
        'pet_id': normalizedPetId,
        'houseHoldId': normalizedHouseholdId,
        'household_id': normalizedHouseholdId,
        'member_id': normalizedMemberId,
        'created_by': normalizedCreatedBy,
        'date': normalizedDate,
        'description': normalizedDescription,
        'time': normalizedStartTime,
        'start': normalizedStartTime,
        'end_time': normalizedEndTime,
        'end': normalizedEndTime,
        'notes': normalizedNotes,
      }..removeWhere((key, value) => value == null);

      await _insertWithMissingColumnFallback(payload);

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