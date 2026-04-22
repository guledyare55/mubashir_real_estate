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
  final bool enableInquiryPopups;
  final DateTime updatedAt;

  // UI Config Flags
  final bool showBedsOnCard;
  final bool showBathsOnCard;
  final bool showTypeOnCard;
  final bool showSizeOnCard;

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
    this.showBedsOnCard = true,
    this.showBathsOnCard = true,
    this.showTypeOnCard = true,
    this.showSizeOnCard = false,
    this.enableInquiryPopups = true,
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
      showBedsOnCard: json['show_beds_on_card'] ?? true,
      showBathsOnCard: json['show_baths_on_card'] ?? true,
      showTypeOnCard: json['show_type_on_card'] ?? true,
      showSizeOnCard: json['show_size_on_card'] ?? false,
      enableInquiryPopups: json['enable_inquiry_popups'] ?? true,
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
      'show_beds_on_card': showBedsOnCard,
      'show_baths_on_card': showBathsOnCard,
      'show_type_on_card': showTypeOnCard,
      'show_size_on_card': showSizeOnCard,
      'enable_inquiry_popups': enableInquiryPopups,
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
    bool? showBedsOnCard,
    bool? showBathsOnCard,
    bool? showTypeOnCard,
    bool? showSizeOnCard,
    bool? enableInquiryPopups,
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
      showBedsOnCard: showBedsOnCard ?? this.showBedsOnCard,
      showBathsOnCard: showBathsOnCard ?? this.showBathsOnCard,
      showTypeOnCard: showTypeOnCard ?? this.showTypeOnCard,
      showSizeOnCard: showSizeOnCard ?? this.showSizeOnCard,
      enableInquiryPopups: enableInquiryPopups ?? this.enableInquiryPopups,
    );
  }
}
