class PantryItem {
  final String id;
  final String householdId;
  final String name;
  final int quantity;
  final String area; // 'FRIDGE', 'PANTRY', 'FREEZER'
  final DateTime? expirationDate;
  final String? barcode;

  PantryItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.quantity,
    required this.area,
    this.expirationDate,
    this.barcode,
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
    );
  }
}