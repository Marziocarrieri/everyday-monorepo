
import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';
import 'package:everyday_app/shared/repositories/supabase_client.dart';

class RecommendedItemRepository {
  Future<List<RecommendedItem>> getItems() async {
    final response = await supabase
        .from('recommended_item')
        .select();

    return (response as List)
        .map((json) => RecommendedItem.fromJson(json))
        .toList();
  }
}