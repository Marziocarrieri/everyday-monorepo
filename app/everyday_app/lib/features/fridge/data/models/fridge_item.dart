import 'area_type.dart';
import 'package:everyday_app/features/fridge/data/models/recommended_item.dart';

class FridgeItem {
  final String id;
  final String householdId;
  final String name;
  final int? quantity;
  final int? weight;
  final String? unit;
  final AreaType area;
  final DateTime? expirationDate;
  final DateTime? createdAt;
  final RecommendedItem? recommendedItem;

  FridgeItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.area,
    this.quantity,
    this.weight,
    this.unit,
    this.expirationDate,
    this.createdAt,
    this.recommendedItem,
  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,

      quantity: json['quantity'] as int?,
      weight: json['weight'] as int?,
      unit: json['unit'] as String?,

      area: AreaTypeX.fromDb(json['area'] as String),

      expirationDate: json['expiration_date'] != null
          ? DateTime.tryParse(json['expiration_date'] as String)
          : null,

      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      recommendedItem: json['recommended_item'] != null 
        ? RecommendedItem.fromJson(json['recommended_item'] as Map<String, dynamic>) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'name': name,
      'quantity': quantity,
      'weight': weight,
      'unit': unit,
      'area': area.dbValue,
      'expiration_date': expirationDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}