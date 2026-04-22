class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final Map<String, bool> notificationPreferences;
  final DateTime createdAt;
  final String? idType;
  final String? idFrontUrl;
   final String? idBackUrl;
  final String? leaseUrl;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.notificationPreferences = const {},
    required this.createdAt,
    this.idType,
    this.idFrontUrl,
    this.idBackUrl,
    this.leaseUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Safely parse JSONB preferences
    final rawPrefs = json['notification_preferences'] as Map<String, dynamic>? ?? {};
    final prefs = rawPrefs.map((key, value) => MapEntry(key, value as bool));

    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      notificationPreferences: prefs,
      createdAt: DateTime.parse(json['created_at']),
      idType: json['id_type'] as String?,
      idFrontUrl: json['id_front_url'] as String?,
      idBackUrl: json['id_back_url'] as String?,
      leaseUrl: json['lease_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'role': role,
      'notification_preferences': notificationPreferences,
      if (idType != null) 'id_type': idType,
      if (idFrontUrl != null) 'id_front_url': idFrontUrl,
      if (idBackUrl != null) 'id_back_url': idBackUrl,
      if (leaseUrl != null) 'lease_url': leaseUrl,
    };
  }
}
