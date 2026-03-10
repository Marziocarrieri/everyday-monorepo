// TODO: legacy household flow – candidate for removal
import 'models/household.dart';
import '../../../shared/repositories/supabase_client.dart';
import '../domain/services/household_service.dart';

class HouseholdFeatureService {
  Future<List<Household>> getUserHouseholds() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('household_member')
        .select('household(*)')
      .eq('user_id', user.id)
      .eq('member_status', 'ACTIVE');

    return List<Map<String, dynamic>>.from(response)
        .map((row) => Household.fromJson(row['household']))
        .toList();
  }

  Future<Household> createHousehold({String name = 'New household'}) async {
    return await HouseholdService().createHousehold(name);
  }
}
