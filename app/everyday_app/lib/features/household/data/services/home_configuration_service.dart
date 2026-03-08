import 'package:flutter/foundation.dart';

import '../models/household_floor.dart';
import '../models/household_room.dart';
import '../repositories/home_configuration_repository.dart';

class HomeConfigurationService {
  final HomeConfigurationRepository _repository = HomeConfigurationRepository();

  Future<List<HouseholdFloor>> loadFloors(String householdId) async {
    try {
      return await _repository.getFloors(householdId);
    } catch (error) {
      debugPrint('Error loading floors: $error');
      rethrow;
    }
  }

  Future<List<HouseholdRoom>> loadRooms({
    required String householdId,
    required String floorId,
  }) async {
    try {
      return await _repository.getRooms(
        householdId: householdId,
        floorId: floorId,
      );
    } catch (error) {
      debugPrint('Error loading rooms: $error');
      rethrow;
    }
  }

  Future<void> addRoom({
    required String householdId,
    required String floorId,
    required String name,
    String? roomType,
  }) async {
    try {
      await _repository.createRoom(
        householdId: householdId,
        floorId: floorId,
        name: name,
        roomType: roomType,
      );
    } catch (error) {
      debugPrint('Error creating room: $error');
      rethrow;
    }
  }

  Future<void> removeRoom(String roomId) async {
    try {
      await _repository.deleteRoom(roomId);
    } catch (error) {
      debugPrint('Error deleting room: $error');
      rethrow;
    }
  }

  Future<void> addFloor({
    required String householdId,
    required String name,
    int? floorOrder,
  }) async {
    try {
      await _repository.createFloor(
        householdId: householdId,
        name: name,
        floorOrder: floorOrder,
      );
    } catch (error) {
      debugPrint('Error creating floor: $error');
      rethrow;
    }
  }
}
