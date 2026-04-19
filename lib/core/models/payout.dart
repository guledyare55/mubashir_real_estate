class Payout {
  final String id;
  final String rentalId;
  final double amount;
  final double agencyCut;
  final double ownerCut;
  final bool isPaidToOwner;
  final DateTime? payoutDate;
  final DateTime createdAt;

  Payout({
    required this.id,
    required this.rentalId,
    required this.amount,
    required this.agencyCut,
    required this.ownerCut,
    this.isPaidToOwner = false,
    this.payoutDate,
    required this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      agencyCut: (json['agency_cut'] as num).toDouble(),
      ownerCut: (json['owner_cut'] as num).toDouble(),
      isPaidToOwner: json['is_paid_to_owner'] as bool? ?? false,
      payoutDate: json['payout_date'] != null ? DateTime.parse(json['payout_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'rental_id': rentalId,
      'amount': amount,
      'agency_cut': agencyCut,
      'owner_cut': ownerCut,
      'is_paid_to_owner': isPaidToOwner,
      'payout_date': payoutDate?.toIso8601String(),
    };
  }
}
