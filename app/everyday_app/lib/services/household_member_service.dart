import '../models/household_member.dart';
import '../repositories/household_repository.dart';

class HouseholdMemberService {
  final HouseholdRepository _repo = HouseholdRepository();

  // Restituisce la lista completa con nomi e foto 
  Future<List<HouseholdMember>> getMembers(String householdId) async {
    return await _repo.getMembers(householdId);
  }

  // Aggiungi un coinquilino
  Future<void> addPerson(String householdId, String userId, String role) async {
    await _repo.addMember(
      householdId: householdId,
      userId: userId,
      role: role,
    );
  }
}