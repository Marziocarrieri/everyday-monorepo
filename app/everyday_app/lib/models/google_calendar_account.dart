class GoogleCalendarAccount {
  final String id;
  final String memberId;
  final String? externalCalendarId;
  final DateTime? lastSync;
  final DateTime? tokenExpiresAt;

  GoogleCalendarAccount({
    required this.id,
    required this.memberId,
    this.externalCalendarId,
    this.lastSync,
    this.tokenExpiresAt,
  });

  factory GoogleCalendarAccount.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarAccount(
      id: json['id'],
      memberId: json['member_id'],
      externalCalendarId: json['external_calendar_id'],
      lastSync: json['last_sync_at'] != null 
          ? DateTime.parse(json['last_sync_at']) 
          : null,
      // Data di scadenza del token
      tokenExpiresAt: json['token_expires_at'] != null 
          ? DateTime.parse(json['token_expires_at']) 
          : null,
    );
  }
}