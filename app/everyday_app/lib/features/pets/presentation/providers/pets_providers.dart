import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/features/pets/data/models/pet.dart';
import 'package:everyday_app/features/pets/data/models/pet_activity.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_activities_repository.dart';
import 'package:everyday_app/features/pets/data/repositories/pets_repository.dart';

class PetsLocalRemovalNotifier extends StateNotifier<Set<String>> {
  PetsLocalRemovalNotifier() : super(<String>{});

  void removePetLocally(String petId) {
    final normalizedId = petId.trim();
    if (normalizedId.isEmpty || state.contains(normalizedId)) {
      return;
    }

    state = <String>{...state, normalizedId};
  }

  void restorePetLocally(String petId) {
    if (!state.contains(petId)) {
      return;
    }

    final next = <String>{...state}..remove(petId);
    state = next;
  }

  void reconcileWithSnapshot(Iterable<String> snapshotIds) {
    if (state.isEmpty) {
      return;
    }

    final liveIds = snapshotIds.toSet();
    final next = state.where(liveIds.contains).toSet();
    if (next.length == state.length) {
      return;
    }

    state = next;
  }
}

class PetActivitiesLocalRemovalNotifier extends StateNotifier<Set<String>> {
  PetActivitiesLocalRemovalNotifier() : super(<String>{});

  void removeActivityLocally(String activityId) {
    final normalizedId = activityId.trim();
    if (normalizedId.isEmpty || state.contains(normalizedId)) {
      return;
    }

    state = <String>{...state, normalizedId};
  }

  void restoreActivityLocally(String activityId) {
    if (!state.contains(activityId)) {
      return;
    }

    final next = <String>{...state}..remove(activityId);
    state = next;
  }

  void reconcileWithSnapshot(Iterable<String> snapshotIds) {
    if (state.isEmpty) {
      return;
    }

    final liveIds = snapshotIds.toSet();
    final next = state.where(liveIds.contains).toSet();
    if (next.length == state.length) {
      return;
    }

    state = next;
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final petActivitiesRepositoryProvider = Provider<PetActivitiesRepository>((ref) {
  return PetActivitiesRepository();
});

final petsLocalRemovalProvider = StateNotifierProvider.family<
    PetsLocalRemovalNotifier,
    Set<String>,
    String>((ref, householdId) {
  return PetsLocalRemovalNotifier();
});

final petActivitiesLocalRemovalProvider = StateNotifierProvider.family<
    PetActivitiesLocalRemovalNotifier,
    Set<String>,
    String>((ref, petId) {
  return PetActivitiesLocalRemovalNotifier();
});

final petsStreamProvider =
    StreamProvider.family<List<Pet>, String>((ref, householdId) {
  final normalizedHouseholdId = householdId.trim();
  if (normalizedHouseholdId.isEmpty) {
    return const Stream<List<Pet>>.empty();
  }

  final repository = ref.watch(petRepositoryProvider);
  return repository
      .watchPets(normalizedHouseholdId)
      .map((pets) => List<Pet>.unmodifiable(List<Pet>.from(pets)));
});

final petActivitiesStreamProvider =
    StreamProvider.family<List<PetActivity>, String>((ref, petId) {
  final normalizedPetId = petId.trim();
  if (normalizedPetId.isEmpty) {
    return const Stream<List<PetActivity>>.empty();
  }

  final repository = ref.watch(petActivitiesRepositoryProvider);
  return repository
      .watchPetActivities(normalizedPetId)
      .map(
        (activities) => List<PetActivity>.unmodifiable(
          List<PetActivity>.from(activities),
        ),
      );
});
