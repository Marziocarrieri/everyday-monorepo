import 'package:everyday_app/core/roles/app_role.dart';

/// Policy centralizzata per la visibilità e gestione dei Task.
/// Sostituisce i controlli sparsi e le stringhe "hardcoded".
class TaskVisibilityPolicy {
  // Costanti per i tipi di visibilità
  static const String visibilityAll = 'ALL';
  static const String visibilityHostOnly = 'HOST_ONLY';

  /// Determina se l'utente corrente può VEDERE un task specifico
  static bool canViewTask({
    required AppRole userRole,
    required String taskVisibility,
    required bool isAssignedToCurrentUser,
  }) {
    // 1. L'Host vede SEMPRE tutto
    if (userRole == AppRole.HOST) return true;

    // 2. Se il task è assegnato direttamente all'utente, lo vede sempre (indipendentemente dal ruolo)
    if (isAssignedToCurrentUser) return true;

    // 3. Se l'utente NON è assegnato al task:
    if (userRole == AppRole.COHOST) {
      // Il Cohost vede i task generali della casa, ma NON quelli privati dell'Host
      return taskVisibility == visibilityAll;
    }

    if (userRole == AppRole.PERSONNEL) {
      // Il Personnel vede SOLO i task assegnati a lui (gestito al punto 2).
      // Non può curiosare tra gli altri task della casa.
      return false; 
    }

    return false;
  }

  /// Determina se l'utente può CREARE un nuovo task
  static bool canCreateTask(AppRole userRole) {
    // Dalla tua matrice: HOST (✅), COHOST (✅), PERSONNEL (❌)
    return userRole == AppRole.HOST || userRole == AppRole.COHOST;
  }

  /// Determina se l'utente può ASSEGNARE un task ad altre persone
  static bool canAssignTask(AppRole userRole) {
    // Dalla tua matrice: HOST (✅), COHOST (❌), PERSONNEL (❌)
    return userRole == AppRole.HOST;
  }

  /// Determina se l'utente può MODIFICARE un task esistente
  static bool canEditTask(AppRole userRole) {
    // Dalla tua matrice: HOST (✅), COHOST (✅), PERSONNEL (❌)
    return userRole == AppRole.HOST || userRole == AppRole.COHOST;
  }
}