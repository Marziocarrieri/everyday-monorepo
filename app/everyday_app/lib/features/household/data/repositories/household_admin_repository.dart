import '../../../../shared/repositories/supabase_client.dart';

class HouseholdAdminRepository {
  Future<void> deleteHousehold(String householdId) async {
    await supabase.from('household').delete().eq('id', householdId);
  }
}
