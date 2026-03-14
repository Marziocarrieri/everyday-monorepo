import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet.dart'; 

class PetRepository {
  String? _readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
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

  Stream<List<Pet>> watchPets(String householdId) {
    final normalizedHouseholdId = householdId.trim();
    if (normalizedHouseholdId.isEmpty) {
      return Stream<List<Pet>>.value(const <Pet>[]);
    }

    late final StreamController<List<Pet>> controller;
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
            'PET UPSERT SKIPPED TOMBSTONE source=$source id=$id',
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
        debugPrint('PET REALTIME EVENT type=$type id=$id source=$source');
      }
    }

    void emitFromCache({required String source}) {
      if (disposed || controller.isClosed) {
        return;
      }

      final filteredRows = stateById.values
          .where(
            (row) => _readString(row['household_id']) == normalizedHouseholdId,
          )
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final nextPets = filteredRows
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
          .toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));

      final emittedSnapshot = List<Pet>.unmodifiable(List<Pet>.from(nextPets));

      if (kDebugMode) {
        if (lastLength != emittedSnapshot.length) {
          debugPrint(
            'PET CACHE LENGTH CHANGED source=$source before=$lastLength after=${emittedSnapshot.length}',
          );
        }
        lastLength = emittedSnapshot.length;

        debugPrint(
          'PET SNAPSHOT EMITTED source=$source length=${emittedSnapshot.length}',
        );
        print(
          'PET STREAM EMIT identity=${identityHashCode(emittedSnapshot)} '
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

    controller = StreamController<List<Pet>>.broadcast(
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
            .from('pets')
            .stream(primaryKey: ['id'])
            .eq('household_id', normalizedHouseholdId)
            .listen((rows) {
              for (final row in rows) {
                final incoming = Map<String, dynamic>.from(row);
                upsertStateRow(
                  incoming,
                  source: 'pets_snapshot_stream',
                );
              }

              emitFromCache(source: 'pets_snapshot_stream');
            }, onError: (Object error, StackTrace stackTrace) {
              if (!disposed && !controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            });

        deleteRealtimeChannel = supabase
            .channel('schema-db-changes:pets-delete:$normalizedHouseholdId')
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'pets',
              callback: (payload) {
                if (payload.eventType != PostgresChangeEvent.delete) {
                  return;
                }

                final deletedId = _readString(payload.oldRecord['id']);
                if (deletedId == null) {
                  return;
                }

                final deletedHouseholdId =
                    _readString(payload.oldRecord['household_id']);
                if (deletedHouseholdId != null &&
                    deletedHouseholdId != normalizedHouseholdId) {
                  return;
                }

                if (kDebugMode) {
                  debugPrint('PET REALTIME DELETE RECEIVED id=$deletedId');
                }

                deletedIds.add(deletedId);
                stateById.remove(deletedId);

                emitFromCache(source: 'pets_delete_realtime');
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