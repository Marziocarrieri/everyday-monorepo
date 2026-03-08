import 'package:everyday_app/features/personnel/data/models/household_member.dart';
import '../../data/repositories/household_repository.dart';
import 'household_service.dart';

class HouseholdMemberService {
  final HouseholdRepository _repo = HouseholdRepository();
  final HouseholdService _householdService = HouseholdService();

  // Restituisce la lista completa con nomi e foto 
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    return await _repo.getMembers(householdId);
  }

  // Aggiungi un coinquilino
  Future<void> addPerson(String householdId, String userId, String role) async {
    await _householdService.addMember(
      householdId: householdId,
      userId: userId,
      role: role,
    );
  }
}