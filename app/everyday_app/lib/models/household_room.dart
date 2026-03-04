class HouseholdRoom {
  final String id;
  final String householdId;
  final String floorId;
  final String name;
  final String? roomType;

  const HouseholdRoom({
    required this.id,
    required this.householdId,
    required this.floorId,
    required this.name,
    this.roomType,
  });

  factory HouseholdRoom.fromJson(Map<String, dynamic> json) {
    return HouseholdRoom(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      floorId: json['floor_id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String)
          : 'Unnamed room',
      roomType: json['room_type'] as String?,
    );
  }
}
