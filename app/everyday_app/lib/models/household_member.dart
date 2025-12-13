import 'user.dart'; // Ci serve importare il modello AppUser

class HouseholdMember {
  final String id;
  final String userId;
  final String householdId;
  final String role; // Il ruolo: 'HOST', 'COHOST', 'PERSONNEL'
  final bool isPersonnel;
  final String? personnelType;
  
  // Relazione (JOIN)
  // Questo campo è il risultato di una "Join" nel database. Se chiediamo i dati extra
  // dell'utente (nome, email), li mettiamo qui dentro.
  final AppUser? profile; 

  HouseholdMember({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.role,
    required this.isPersonnel,
    this.personnelType,
    this.profile,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'],
      userId: json['user_id'],
      householdId: json['household_id'],
      role: json['role'],
      isPersonnel: json['is_personnel'] ?? false,
      personnelType: json['personnel_type'],
      
      // Gestione Oggetti Annidati
      // Se nel JSON c'è un pezzo chiamato 'users_profile' e non è vuoto, 
      // usiamo il traduttore di AppUser (AppUser.fromJson) per convertirlo.
      profile: json['users_profile'] != null 
          ? AppUser.fromJson(json['users_profile']) 
          : null,
    );
  }
}