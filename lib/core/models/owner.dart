class Owner {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? bankDetails;
  final DateTime createdAt;

  Owner({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.bankDetails,
    required this.createdAt,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      bankDetails: json['bank_details'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'bank_details': bankDetails,
    };
  }
}
