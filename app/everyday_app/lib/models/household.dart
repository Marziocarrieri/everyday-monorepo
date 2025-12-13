class Household {
  final String id;
  final String name;
  final String? address;
  final String timezone; // 'Europe/Rome' o altro

  Household({
    required this.id,
    required this.name,
    this.address,
    required this.timezone,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      // Valore di Default (??)
      // Se il database non ci ha dato il timezone, noi gli diamo un default 'Europe/Rome'
      // per essere sicuri che la nostra app non si rompa mai.
      timezone: json['timezone'] ?? 'Europe/Rome', 
    );
  }
}