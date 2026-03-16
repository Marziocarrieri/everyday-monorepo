import 'package:everyday_app/shared/models/user.dart'; // Ci serve importare il modello AppUser

class HouseholdMember {
  final String id;
  final String userId;
  final String householdId;
  final String role; // Il ruolo: 'HOST', 'COHOST', 'PERSONNEL'
  final bool isPersonnel;
  final String? personnelType;
  
  // --- AGGIUNTO IL NICKNAME QUI ---
  final String? nickname; 
  final String? avatarUrl; // <-- Aggiunto l'avatarUrl
  
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
    this.nickname, // <-- Aggiunto al costruttore
    this.avatarUrl,
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
      nickname: json['nickname'], // <-- Mappato dal JSON del database
      avatarUrl: json['avatar_url'], // <-- Mappato dal JSON del database
      
      // Gestione Oggetti Annidati
      // Se nel JSON c'è un pezzo chiamato 'profile' e non è vuoto, 
      // usiamo il traduttore di AppUser (AppUser.fromJson) per convertirlo.
      profile: json['profile'] != null 
          ? AppUser.fromJson(json['profile']) 
          : null,
    );
  }
}