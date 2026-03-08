class HouseholdFloor {
  final String id;
  final String householdId;
  final String name;
  final int floorOrder;

  const HouseholdFloor({
    required this.id,
    required this.householdId,
    required this.name,
    required this.floorOrder,
  });

  factory HouseholdFloor.fromJson(Map<String, dynamic> json) {
    return HouseholdFloor(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String)
          : 'Unnamed floor',
      floorOrder: (json['floor_order'] as num?)?.toInt() ?? 0,
    );
  }
}
