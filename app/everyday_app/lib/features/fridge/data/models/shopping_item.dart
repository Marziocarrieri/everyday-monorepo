import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';

class ShoppingItem {
  final String id;
  final String householdId;
  final String name;
  final int quantity;
  final String status; // 'PENDING', 'BOUGHT'
  final RecommendedItem? recommendedItem ;

  ShoppingItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    required this.status,
    this.recommendedItem,

  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      quantity: json['quantity'] ?? 1,  //quell' 1 vuol dire che se la quantità non è specificata, sarà 1
      status: json['status'] ?? 'PENDING', //PENDING vuol dire "da comprare", in modo da avere tre stati invece che due 
      recommendedItem: json['recommended_item'] != null 
        ? RecommendedItem.fromJson(json['recommended_item'] as Map<String, dynamic>) 
        : null,
    );
  }
}