class DietDocument {
  final String id;
  final String memberId;
  final String url; // Il link per scaricare il file (nel Supabase Storage)
  final DateTime uploadedAt;

  DietDocument({
    required this.id,
    required this.memberId,
    required this.url,
    required this.uploadedAt,
  });

  factory DietDocument.fromJson(Map<String, dynamic> json) {
    return DietDocument(
      id: json['id'],
      memberId: json['member_id'],
      url: json['url'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}