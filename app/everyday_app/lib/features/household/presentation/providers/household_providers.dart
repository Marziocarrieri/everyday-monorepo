import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyday_app/core/providers/app_providers.dart';
import 'package:everyday_app/features/household/domain/services/household_service.dart';

final householdServiceProvider = Provider<HouseholdService>((ref) {
  final repository = ref.watch(householdRepositoryProvider);
  return HouseholdService(householdRepository: repository);
});
