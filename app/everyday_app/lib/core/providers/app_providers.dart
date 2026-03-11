import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:everyday_app/core/app_context.dart';
import 'package:everyday_app/features/fridge/data/repositories/fridge_repository.dart';
import 'package:everyday_app/features/fridge/data/repositories/shopping_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_member_repository.dart';
import 'package:everyday_app/features/household/data/repositories/household_repository.dart';
import 'package:everyday_app/features/tasks/data/repositories/task_repository.dart';
import 'package:everyday_app/shared/repositories/diet_repository.dart';

final appContextProvider = ChangeNotifierProvider<AppContext>((ref) {
  return AppContext.instance;
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return auth.onAuthStateChange.map((event) => event.session);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final fridgeRepositoryProvider = Provider<FridgeRepository>((ref) {
  return FridgeRepository();
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

final householdMemberRepositoryProvider =
    Provider<HouseholdMemberRepository>((ref) {
  return HouseholdMemberRepository();
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository();
});

final dietRepositoryProvider = Provider<DietRepository>((ref) {
  return DietRepository();
});
