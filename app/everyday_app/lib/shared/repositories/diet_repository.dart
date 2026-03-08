import 'supabase_client.dart';

class DietRepository {
  Future<Map<String, dynamic>?> getLatestDietForUser(String userId) async {
    final response = await supabase
        .from('diet_document')
        .select('id, user_id, url, uploaded_at')
        .eq('user_id', userId)
        .order('uploaded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> insertDietDocument({
    required String userId,
    required String url,
  }) async {
    await supabase.from('diet_document').insert({
      'user_id': userId,
      'url': url,
    });
  }

  Future<void> deleteDietDocument({
    required String docId,
    required String userId,
  }) async {
    await supabase
        .from('diet_document')
        .delete()
        .eq('id', docId)
        .eq('user_id', userId);
  }
}
