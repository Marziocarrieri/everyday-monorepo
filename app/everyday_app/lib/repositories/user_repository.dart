import '../models/user.dart'; // Importiamo lo stampino "AppUser"
import 'supabase_client.dart'; // Importiamo il telecomando

class UserRepository {
  
  // FUNZIONE: Scarica il profilo di un utente
  // "Future" significa: "Ti prometto che ti darò un AppUser, dammi un attimo di tempo".
  // "AppUser?" col punto di domanda significa: "Potrei non trovare nulla (null)".
  Future<AppUser?> getProfile(String userId) async {
    try {
      // 1. LA CHIAMATA
      // Usiamo il telecomando 'supabase'.
      // .from('users_profile') -> Vai allo scaffale 'users_profile'.
      // .select() -> Prendi i dati.
      // .eq('id', userId) -> PRENDI SOLO QUELLO DOVE L'ID È UGUALE A 'userId'.
      // .single() -> Mi aspetto una sola scatola, non una lista.
      final data = await supabase
          .from('users_profile')
          .select()
          .eq('id', userId)
          .single();

      // 2. LA TRASFORMAZIONE
      // 'data' è un mucchio di dati grezzi (JSON).
      // Usiamo il nostro "stampino" (fromJson) per creare un oggetto AppUser ordinato.
      return AppUser.fromJson(data);

    } catch (e) {
      // Se qualcosa va storto (internet non va, tabella non trovata), stampiamo l'errore
      print('Errore nel recupero profilo: $e');
      return null; // Restituiamo "niente"
    }
  }

  // FUNZIONE: Aggiorna il profilo (es. cambia nome)
  Future<void> updateProfile(String userId, Map<String, dynamic> nuoviDati) async {
    // .update(nuoviDati) -> Modifica i dati con quelli nuovi
    // .eq('id', userId) -> Ma fallo SOLO sulla riga di questo utente!
    await supabase.from('users_profile').update(nuoviDati).eq('id', userId);
  }
}