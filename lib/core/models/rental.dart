class Rental {
  final String id;
  final String propertyId;
  final String? tenantId;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double commissionRate;
  final String status;
  final String? agentId;
  final DateTime createdAt;

  Rental({
    required this.id,
    required this.propertyId,
    this.tenantId,
    required this.startDate,
    this.endDate,
    required this.monthlyRent,
    this.commissionRate = 10.0,
    this.status = 'Active',
    this.agentId,
    required this.createdAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      tenantId: json['tenant_id'] as String?,
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 10.0,
      status: json['status'] as String? ?? 'Active',
      agentId: json['agent_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      'tenant_id': tenantId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'monthly_rent': monthlyRent,
      'commission_rate': commissionRate,
      'status': status,
      'agent_id': agentId,
    };
  }
}
