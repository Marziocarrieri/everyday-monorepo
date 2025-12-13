class Pet {
  final String id;
  final String householdId;
  final String name;
  //final String? species;
  //final String? breed;   
  //final DateTime? birthdate;

  Pet({
    required this.id,
    required this.householdId,
    required this.name,
    //this.species,
    //this.breed,
    //this.birthdate,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      householdId: json['household_id'],
      name: json['name'],
      //species: json['species'],
      //breed: json['breed'],
      //birthdate: json['birthdate'] != null 
          //? DateTime.parse(json['birthdate']) 
          //: null,
    );
  }
}