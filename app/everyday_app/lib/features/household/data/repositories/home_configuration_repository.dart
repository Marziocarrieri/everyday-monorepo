import 'package:flutter/foundation.dart';

import '../models/home_configuration.dart';
import '../models/household_floor.dart';
import '../models/household_room.dart';
import '../../../../shared/repositories/supabase_client.dart';

class HomeConfigurationRepository {
  bool _isMissingColumnError(Object error, String columnName) {
    final message = error.toString().toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('column') || message.contains('schema cache'));
  }

  Future<List<HouseholdFloor>> getFloors(String householdId) async {
    try {
      final response = await supabase
          .from('household_floor')
          .select('id, household_id, name, floor_order, created_at')
          .eq('household_id', householdId)
          .order('floor_order', ascending: true)
          .order('created_at', ascending: true);

      final floors = List<Map<String, dynamic>>.from(response)
          .map(HouseholdFloor.fromJson)
          .toList();

      floors.sort((left, right) {
        final byOrder = left.floorOrder.compareTo(right.floorOrder);
        if (byOrder != 0) return byOrder;
        return left.name.compareTo(right.name);
      });

      return floors;
    } catch (error) {
      if (!_isMissingColumnError(error, 'floor_order')) {
        rethrow;
      }

      debugPrint('floor_order not available, using fallback floor sorting: $error');
      final fallbackResponse = await supabase
          .from('household_floor')
          .select('id, household_id, name, created_at')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      final floors = List<Map<String, dynamic>>.from(fallbackResponse)
          .map(
            (row) => HouseholdFloor.fromJson({
              ...row,
              'floor_order': 0,
            }),
          )
          .toList();

      floors.sort((left, right) {
        final byOrder = left.floorOrder.compareTo(right.floorOrder);
        if (byOrder != 0) return byOrder;
        return left.name.compareTo(right.name);
      });

      return floors;
    }
  }

  Stream<List<HouseholdFloor>> watchFloors(String householdId) {
    final cachedRowsById = <String, Map<String, dynamic>>{};

    return supabase
        .from('household_floor')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final nextRowsById = <String, Map<String, dynamic>>{};

          for (final row in rows) {
            final incoming = Map<String, dynamic>.from(row);
            final id = incoming['id']?.toString();
            if (id == null || id.isEmpty) {
              continue;
            }

            final previous = cachedRowsById[id];
            nextRowsById[id] = previous == null
                ? incoming
                : <String, dynamic>{...previous, ...incoming};
          }

          cachedRowsById
            ..clear()
            ..addAll(nextRowsById);

          final filteredRows = cachedRowsById.values
              .where((row) => row['household_id'] == householdId)
              .toList();

          final floors = filteredRows.map(HouseholdFloor.fromJson).toList();
          floors.sort((left, right) {
            final byOrder = left.floorOrder.compareTo(right.floorOrder);
            if (byOrder != 0) return byOrder;
            return left.name.compareTo(right.name);
          });

          return floors;
        });
  }

  Future<List<HouseholdRoom>> getRooms({
    required String householdId,
    required String floorId,
  }) async {
    try {
      final response = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name, room_type')
          .eq('household_id', householdId)
          .eq('floor_id', floorId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(HouseholdRoom.fromJson)
          .toList();
    } catch (error) {
      if (!_isMissingColumnError(error, 'room_type')) {
        rethrow;
      }

      debugPrint('room_type not available, loading rooms without type: $error');
      final fallbackResponse = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name')
          .eq('household_id', householdId)
          .eq('floor_id', floorId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(fallbackResponse)
          .map(
            (row) => HouseholdRoom.fromJson({
              ...row,
              'room_type': null,
            }),
          )
          .toList();
    }
  }

  Stream<List<HouseholdRoom>> watchRooms(String householdId) {
    final cachedRowsById = <String, Map<String, dynamic>>{};

    return supabase
        .from('household_room')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final nextRowsById = <String, Map<String, dynamic>>{};

          for (final row in rows) {
            final incoming = Map<String, dynamic>.from(row);
            final id = incoming['id']?.toString();
            if (id == null || id.isEmpty) {
              continue;
            }

            final previous = cachedRowsById[id];
            nextRowsById[id] = previous == null
                ? incoming
                : <String, dynamic>{...previous, ...incoming};
          }

          cachedRowsById
            ..clear()
            ..addAll(nextRowsById);

          final filteredRows = cachedRowsById.values
              .where((row) => row['household_id'] == householdId)
              .toList();

          return filteredRows.map(HouseholdRoom.fromJson).toList();
        });
  }

  Stream<HomeConfiguration?> watchHomeConfiguration(String householdId) {
    return supabase
        .from('home_configuration')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return HomeConfiguration.fromMap(
            Map<String, dynamic>.from(rows.first),
          );
        });
  }

  Future<List<HouseholdRoom>> getRoomsForHousehold(String householdId) async {
    try {
      final response = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name, room_type')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(HouseholdRoom.fromJson)
          .toList();
    } catch (error) {
      if (!_isMissingColumnError(error, 'room_type')) {
        rethrow;
      }

      debugPrint('room_type not available, loading rooms without type: $error');
      final fallbackResponse = await supabase
          .from('household_room')
          .select('id, household_id, floor_id, name')
          .eq('household_id', householdId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(fallbackResponse)
          .map(
            (row) => HouseholdRoom.fromJson({
              ...row,
              'room_type': null,
            }),
          )
          .toList();
    }
  }

  Future<void> createRoom({
    required String householdId,
    required String floorId,
    required String name,
    String? roomType,
  }) async {
    final payload = <String, dynamic>{
      'household_id': householdId,
      'floor_id': floorId,
      'name': name,
    };

    if (roomType != null && roomType.trim().isNotEmpty) {
      payload['room_type'] = roomType.trim();
    }

    try {
      await supabase.from('household_room').insert(payload);
    } catch (error) {
      final includeRoomType = payload.containsKey('room_type');
      if (!includeRoomType || !_isMissingColumnError(error, 'room_type')) {
        rethrow;
      }

      debugPrint('room_type not available, inserting room without type: $error');
      payload.remove('room_type');
      await supabase.from('household_room').insert(payload);
    }
  }

  Future<void> createFloor({
    required String householdId,
    required String name,
    int? floorOrder,
  }) async {
    final payload = <String, dynamic>{
      'household_id': householdId,
      'name': name,
    };

    if (floorOrder != null) {
      payload['floor_order'] = floorOrder;
    }

    try {
      await supabase.from('household_floor').insert(payload);
    } catch (error) {
      final includesOrder = payload.containsKey('floor_order');
      if (!includesOrder || !_isMissingColumnError(error, 'floor_order')) {
        rethrow;
      }

      debugPrint('floor_order not available, creating floor without order: $error');
      payload.remove('floor_order');
      await supabase.from('household_floor').insert(payload);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    await supabase.from('household_room').delete().eq('id', roomId);
  }
}
