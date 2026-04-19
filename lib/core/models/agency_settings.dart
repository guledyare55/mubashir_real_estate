class AgencySettings {
  final int id;
  final String name;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String currencySymbol;
  final bool isMaintenanceMode;
  final double defaultCommissionRate;
  final String? supportPhone;
  final DateTime updatedAt;

  AgencySettings({
    required this.id,
    required this.name,
    this.logoUrl,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.currencySymbol = r'$',
    this.isMaintenanceMode = false,
    this.defaultCommissionRate = 10.0,
    this.supportPhone,
    required this.updatedAt,
  });

  factory AgencySettings.fromJson(Map<String, dynamic> json) {
    return AgencySettings(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? 'Mubashir Real Estate',
      logoUrl: json['logo_url'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      currencySymbol: json['currency_symbol'] ?? r'$',
      isMaintenanceMode: json['is_maintenance_mode'] ?? false,
      defaultCommissionRate:
          (json['default_commission_rate'] as num?)?.toDouble() ?? 10.0,
      supportPhone: json['support_phone'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'currency_symbol': currencySymbol,
      'is_maintenance_mode': isMaintenanceMode,
      'default_commission_rate': defaultCommissionRate,
      'support_phone': supportPhone,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AgencySettings copyWith({
    String? name,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? currencySymbol,
    bool? isMaintenanceMode,
    double? defaultCommissionRate,
    String? supportPhone,
  }) {
    return AgencySettings(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      defaultCommissionRate:
          defaultCommissionRate ?? this.defaultCommissionRate,
      supportPhone: supportPhone ?? this.supportPhone,
      updatedAt: DateTime.now(),
    );
  }
}
