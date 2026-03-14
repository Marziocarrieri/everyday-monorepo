import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/features/pets/data/models/pet.dart';
import 'package:everyday_app/features/pets/data/models/pet_activity.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_activities_repository.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_repository.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final petActivitiesRepositoryProvider = Provider<PetActivitiesRepository>((ref) {
  return PetActivitiesRepository();
});

final petsStreamProvider =
    StreamProvider.family<List<Pet>, String>((ref, householdId) {
  if (householdId.trim().isEmpty) {
    return const Stream<List<Pet>>.empty();
  }

  final repository = ref.watch(petRepositoryProvider);
  return repository
      .watchPets(householdId)
      .map((pets) => List<Pet>.from(pets));
});

final petActivitiesStreamProvider =
    StreamProvider.family<List<PetActivity>, String>((ref, petId) {
  if (petId.trim().isEmpty) {
    return const Stream<List<PetActivity>>.empty();
  }

  final repository = ref.watch(petActivitiesRepositoryProvider);
  return repository
      .watchPetActivities(petId)
      .map((activities) => List<PetActivity>.from(activities));
});
