class Pet {
  final String id;
  final String householdId;
  final String name;
  final String? species;
  //final String? breed;   
  //final DateTime? birthdate;

  Pet({
    required this.id,
    required this.householdId,
    required this.name,
    this.species,
    //this.breed,
    //this.birthdate,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['id']);
    final householdId = _asString(json['household_id']);
    final name = _asString(json['name']);

    if (id.isEmpty || householdId.isEmpty || name.isEmpty) {
      throw const FormatException('Invalid pet row');
    }

    return Pet(
      id: id,
      householdId: householdId,
      name: name,
      species: _asNullableString(json['species']),
      //breed: json['breed'],
      //birthdate: json['birthdate'] != null 
          //? DateTime.parse(json['birthdate']) 
          //: null,
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }
}