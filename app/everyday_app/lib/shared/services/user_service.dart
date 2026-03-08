import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'auth_service.dart';

class UserService {
  // Il Manager (UserService) ha bisogno di due assistenti:
  // 1. AuthService: Per sapere CHI è loggato (l'ID).
  // 2. UserRepository: Per andare a prendere i dati nel magazzino.
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  // Restituisce il profilo completo dell'utente loggato.
  Future<AppUser?> getCurrentUserProfile() async {
    // Chiedo l'ID di chi è loggato
    final user = _authService.currentUser;
    
    // Se nessuno è loggato (null), mi fermo subito.
    if (user == null) return null;

    // Ora che ho l'ID, uso la repository per ottenere il profilo
    return await _userRepository.getProfile(user.id);
  }

  // Aggiorna il mio nome
  Future<void> updateName(String newName) async {
    final user = _authService.currentUser;
    if (user == null) return; // Sicurezza: se non sei loggato, non fai nulla.

    // Ordino alla repository di aggiornare.
    await _userRepository.updateProfile(user.id, {'name': newName});
  }
}