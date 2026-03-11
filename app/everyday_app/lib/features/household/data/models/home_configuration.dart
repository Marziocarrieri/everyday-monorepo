class HomeConfiguration {
  final String id;
  final String householdId;
  final Map<String, dynamic> raw;

  const HomeConfiguration({
    required this.id,
    required this.householdId,
    required this.raw,
  });

  factory HomeConfiguration.fromMap(Map<String, dynamic> map) {
    return HomeConfiguration(
      id: map['id'] as String,
      householdId: map['household_id'] as String,
      raw: Map<String, dynamic>.from(map),
    );
  }
}
