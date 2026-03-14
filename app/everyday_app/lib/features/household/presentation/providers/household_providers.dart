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
  return repository.watchFloors(householdId);
});

final roomsStreamProvider =
    StreamProvider.family<List<HouseholdRoom>, String>((ref, householdId) {
  final repository = ref.watch(homeConfigurationRepositoryProvider);
  return repository.watchRooms(householdId);
});

final homeConfigurationStreamProvider =
    StreamProvider.family<HomeConfiguration?, String>((ref, householdId) {
  final repository = ref.watch(homeConfigurationRepositoryProvider);
  return repository.watchHomeConfiguration(householdId);
});
