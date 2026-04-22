class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final Map<String, bool> notificationPreferences;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.notificationPreferences = const {},
    required this.createdAt,
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
    };
  }
}
