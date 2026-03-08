class AppUser {
  // 1. LE PROPRIETÀ (Cosa sono i dati)
  // 'final' significa che, una volta che l'oggetto è creato, il suo ID non cambia.
  // Il '?' (punto interrogativo) significa "Questo campo è opzionale, potrebbe essere null".
  final String id;
  final String? name;
  final String? email;
  final DateTime? birthdate; // Usiamo DateTime perché è un oggetto Data/Ora
  final String? avatarUrl;

  // 2. IL COSTRUTTORE (Come si crea l'oggetto)
  AppUser({
    required this.id, // 'required' significa che l'ID è obbligatorio
    this.name,
    this.email,
    this.birthdate,
    this.avatarUrl,
  });

  // 3. IL TRADUTTORE: factory AppUser.fromJson(Map<String, dynamic> json)
  // Questa è la "fabbrica" (factory) che crea l'oggetto AppUser partendo dal JSON
  // Map<String, dynamic> servirà a creare una lista, con stringhe che riguardano i nomi
  // dynamic invece ci permetterà di non dover specificare nel secondo caso se usiamo int, stryng etc.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      
      // DateTime.parse
      // Il database memorizza la data di nascita come stringa (testo).
      // Se la stringa esiste (json['birthdate'] != null), usiamo 'DateTime.parse()'
      // per trasformarla in un oggetto data che Flutter può usare (es. per calcolare l'età).
      birthdate: json['birthdate'] != null 
          ? DateTime.parse(json['birthdate']) 
          : null,
          
      // Nomi delle Colonne
      // Nel DB si usa 'snake_case' (avatar_url), qui usiamo 'camelCase' (avatarUrl).
      avatarUrl: json['avatar_url'], 
    );
  }
}