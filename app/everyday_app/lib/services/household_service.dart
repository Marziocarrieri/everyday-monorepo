import '../models/household.dart';
import '../repositories/household_repository.dart';
import 'auth_service.dart';

class HouseholdService {
  final HouseholdRepository _repo = HouseholdRepository();
  final AuthService _auth = AuthService();

  // Crea una nuova casa e coordina il lavoro
  Future<void> createHousehold(String name, String address) async {
    // Controllo di sicurezza
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Devi essere loggato per creare una casa!");
    }

    // Creo la casa
    // Uso l'household_repository per  creare la riga nella tabella 'household'.
    // Lui mi risponde dandomi l'ID della nuova casa
    final householdId = await _repo.createHousehold(name, address);

    // Nomina ad amministratore
    // Uso l'Id ottenuto prima per andare a inserire come HOST l'utente che ha creato la casa
    await _repo.addMember(
      householdId: householdId,
      userId: user.id,
      role: 'HOST',
    );
    
  }

  // Lista delle proprie case
  Future<List<Household>> getMyHouseholds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    return await _repo.getHouseholdsForUser(user.id);
  }
}