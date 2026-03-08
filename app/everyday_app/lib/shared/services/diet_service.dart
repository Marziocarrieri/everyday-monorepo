import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diet_document.dart'; 

class DietService {
  // Anche qui usiamo una chiamata diretta
  final _supabase = Supabase.instance.client;

  // Scarica le diete di un utente
  Future<List<DietDocument>> getMemberDiets(String memberId) async {
    try {
      final response = await _supabase
          .from('diet_document') // Tabella corretta
          .select()
          .eq('member_id', memberId) // Solo di questa persona
          .order('uploaded_at', ascending: false); // I più recenti in alto

      // Trasformiamo i dati grezzi in oggetti DietDocument
      return (response as List)
          .map((json) => DietDocument.fromJson(json))
          .toList();
          
    } catch (e) {
      return [];
    }
  }

  // Salvare il link del documento
  // Questa funzione si chiama DOPO che hai caricato il file e hai ottenuto l'URL.
  Future<void> saveDietUrl(String memberId, String url) async {
    await _supabase.from('diet_document').insert({
      'member_id': memberId,
      'url': url,
      // 'uploaded_at' lo mette in automatico il database (now())
    });
  }

  // Cancellare il documento
  Future<void> deleteDocument(String docId) async {
    await _supabase.from('diet_document').delete().eq('id', docId);
  }
}