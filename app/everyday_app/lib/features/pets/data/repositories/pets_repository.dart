import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
import '../../../../shared/repositories/supabase_client.dart';
import '../models/pet.dart'; 

class PetRepository {
  final Map<String, Map<String, dynamic>> _cachedPetsRowsById = {};
  List<Pet> _cachedPets = const <Pet>[];

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

  Stream<List<Pet>> watchPets(String householdId) {
    final normalizedHouseholdId = householdId.trim();
    if (normalizedHouseholdId.isEmpty) {
      return Stream<List<Pet>>.value(const <Pet>[]);
    }

    late final StreamController<List<Pet>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? snapshotSubscription;
    RealtimeChannel? deleteRealtimeChannel;
    var disposed = false;
    String? lastSnapshotSignature;

    void emitFromCache({required String source}) {
      if (disposed || controller.isClosed) {
        return;
      }

      final filteredRows = _cachedPetsRowsById.values
          .where(
            (row) => _readString(row['household_id']) == normalizedHouseholdId,
          )
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      final snapshotSignature = _buildSnapshotSignature(filteredRows);
      if (kDebugMode && snapshotSignature == lastSnapshotSignature) {
        debugPrint('PET SNAPSHOT SIGNATURE unchanged=$snapshotSignature');
      }
      lastSnapshotSignature = snapshotSignature;

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
          .toList(growable: false);

      final previousLength = _cachedPets.length;
      _cachedPets = List<Pet>.from(nextPets);
      final emittedSnapshot = List<Pet>.unmodifiable(List<Pet>.from(_cachedPets));

      if (kDebugMode) {
        if (previousLength != _cachedPets.length) {
          debugPrint(
            'PET CACHE LENGTH CHANGED source=$source before=$previousLength after=${_cachedPets.length}',
          );
        }
        debugPrint(
          'PET SNAPSHOT EMITTED source=$source length=${emittedSnapshot.length}',
        );
        print(
          'PET STREAM EMIT identity=${identityHashCode(_cachedPets)} '
          'length=${_cachedPets.length}',
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
        _cachedPetsRowsById.clear();
        _cachedPets = const <Pet>[];
        lastSnapshotSignature = null;

        snapshotSubscription = supabase
            .from('pets')
            .stream(primaryKey: ['id'])
            .eq('household_id', normalizedHouseholdId)
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

              _cachedPetsRowsById
                ..clear()
                ..addAll(nextRowsById);

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

                final existed = _cachedPetsRowsById.remove(deletedId) != null;
                if (!existed) {
                  return;
                }

                _cachedPets = List<Pet>.from(_cachedPets)
                  ..removeWhere((pet) => pet.id == deletedId);

                emitFromCache(source: 'pets_delete_realtime');
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