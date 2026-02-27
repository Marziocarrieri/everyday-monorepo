class FridgeItem {
  final String id;
  final String householdId;
  final String name;
  final DateTime? createdAt;

  FridgeItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.createdAt,
  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
