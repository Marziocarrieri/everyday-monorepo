class DietDocument {
  final String id;
  final String householdId;
  final String userId;
  final String url; // Il link per scaricare il file (nel Supabase Storage)
  final DateTime uploadedAt;

  DietDocument({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.url,
    required this.uploadedAt,
  });

  factory DietDocument.fromJson(Map<String, dynamic> json) {
    return DietDocument(
      id: json['id'],
      householdId: json['household_id'],
      userId: json['user_id'],
      url: json['url'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}