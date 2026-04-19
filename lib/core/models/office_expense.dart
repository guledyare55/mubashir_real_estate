class OfficeExpense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  OfficeExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory OfficeExpense.fromJson(Map<String, dynamic> json) {
    return OfficeExpense(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String().split('T')[0],
    };
  }
}
