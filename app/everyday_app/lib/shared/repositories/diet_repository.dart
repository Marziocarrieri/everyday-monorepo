import 'supabase_client.dart';
import 'package:everyday_app/shared/models/diet_document.dart';

class DietRepository {
  Stream<DietDocument?> watchDiet(String householdId) {
    return supabase
        .from('diet_document')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .map((rows) {
          final dietRows = rows
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          if (dietRows.isEmpty) {
            return null;
          }

          dietRows.sort((left, right) {
            final leftDate = DateTime.tryParse(
              left['uploaded_at']?.toString() ?? '',
            );
            final rightDate = DateTime.tryParse(
              right['uploaded_at']?.toString() ?? '',
            );

            final normalizedLeft =
                leftDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final normalizedRight =
                rightDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            return normalizedRight.compareTo(normalizedLeft);
          });

          return DietDocument.fromJson(dietRows.first);
        });
  }

  Future<void> insertDietDocument({
    required String householdId,
    required String userId,
    required String url,
  }) async {
    await supabase.from('diet_document').insert({
      'household_id': householdId,
      'user_id': userId,
      'url': url,
    });
  }

  Future<void> deleteDietDocument({
    required String docId,
    required String householdId,
    required String userId,
  }) async {
    await supabase
        .from('diet_document')
        .delete()
        .eq('id', docId)
        .eq('household_id', householdId)
        .eq('user_id', userId);
  }
}
