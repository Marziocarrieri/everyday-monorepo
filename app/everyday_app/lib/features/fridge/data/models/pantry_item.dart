import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';

class PantryItem {
  final String id;
  final String householdId;
  final String name;
  final int quantity;
  final String area; // 'FRIDGE', 'PANTRY', 'FREEZER'
  final DateTime? expirationDate;
  final String? barcode;
  final RecommendedItem? recommendedItem ;


  PantryItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    required this.area,
    this.expirationDate,
    this.barcode,
    this.recommendedItem,

  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      quantity: json['quantity'] ?? 1,
      area: json['area'],
      expirationDate: json['expiration_date'] != null 
          ? DateTime.parse(json['expiration_date']) 
          : null,
      barcode: json['barcode'],
      recommendedItem: json['recommended_item'] != null 
        ? RecommendedItem.fromJson(json['recommended_item'] as Map<String, dynamic>) 
        : null,
    );
  }
}