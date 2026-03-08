import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // ci serve il client di Supabase. Lo rendiamo privato (_supabase)
  // perché lo useremo solo qui dentro.
  final _supabase = Supabase.instance.client;

  // Uno "Stream" è un flusso di dati continuo.
  // Qui stiamo dicendo: "Tienimi informato in tempo reale se l'utente fa login o logout".
  // Se esce "Loggato", mostra la Home. Se esce "Nessuno", mostra la Login.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Una semplice proprietà per sapere "chi c'è" in questo momento.
  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up
  Future<AuthResponse> signUp(String email, String password, String name) async {
    // Chiamiamo Supabase per creare l'utente protetto
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      // Supabase Auth gestisce email/password. Se vogliamo salvare subito anche il nome, lo mettiamo in data 
      // (Nota: Il vero profilo lo salverà il database grazie a un automatismo SQL che vedremo, o manualmente).
      data: {'name': name}, 
    );
    return response;
  }

  // (Sign In)
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // (Logout)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}