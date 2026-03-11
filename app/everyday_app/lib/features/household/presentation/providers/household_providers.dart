import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/features/household/data/models/home_configuration.dart';
import 'package:everyday_app/features/household/data/models/household_floor.dart';
import 'package:everyday_app/features/household/data/models/household_room.dart';
import 'package:everyday_app/features/household/data/repositories/home_configuration_repository.dart';
import 'package:everyday_app/features/household/domain/services/household_service.dart';

final householdServiceProvider = Provider<HouseholdService>((ref) {
  final repository = ref.watch(householdRepositoryProvider);
  return HouseholdService(householdRepository: repository);
});

final homeConfigurationRepositoryProvider =
    Provider<HomeConfigurationRepository>((ref) {
  return HomeConfigurationRepository();
});

final floorsStreamProvider =
    StreamProvider.family<List<HouseholdFloor>, String>((ref, householdId) {
  final repository = ref.watch(homeConfigurationRepositoryProvider);
  Set<String>? previousFloorIds;

  return repository.watchFloors(householdId).map((floors) {
    final currentFloorIds = floors.map((floor) => floor.id).toSet();
    final didDeleteFloor = previousFloorIds != null &&
        previousFloorIds!.difference(currentFloorIds).isNotEmpty;
    previousFloorIds = currentFloorIds;

    if (didDeleteFloor) {
      Future.microtask(ref.invalidateSelf);
    }

    return floors;
  });
});

final roomsStreamProvider =
    StreamProvider.family<List<HouseholdRoom>, String>((ref, householdId) {
  final repository = ref.watch(homeConfigurationRepositoryProvider);
  Set<String>? previousRoomIds;

  return repository.watchRooms(householdId).map((rooms) {
    final currentRoomIds = rooms.map((room) => room.id).toSet();
    final didDeleteRoom = previousRoomIds != null &&
        previousRoomIds!.difference(currentRoomIds).isNotEmpty;
    previousRoomIds = currentRoomIds;

    if (didDeleteRoom) {
      Future.microtask(ref.invalidateSelf);
    }

    return rooms;
  });
});

final homeConfigurationStreamProvider =
    StreamProvider.family<HomeConfiguration?, String>((ref, householdId) {
  final repository = ref.watch(homeConfigurationRepositoryProvider);
  return repository.watchHomeConfiguration(householdId);
});
