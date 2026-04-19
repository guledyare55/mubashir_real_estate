class Employee {
  final String id;
  final String name;
  final String role;
  final double salary;
  final String? phone;
  final String? email;
  final DateTime joinedAt;
  final DateTime lastPayDate;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.salary,
    this.phone,
    this.email,
    required this.joinedAt,
    required this.lastPayDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      salary: (json['salary'] as num).toDouble(),
      phone: json['phone'],
      email: json['email'],
      joinedAt: DateTime.parse(json['joined_at']),
      lastPayDate: json['last_pay_date'] != null ? DateTime.parse(json['last_pay_date']) : DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'salary': salary,
      'phone': phone,
      'email': email,
      'joined_at': joinedAt.toIso8601String().split('T')[0],
      'last_pay_date': lastPayDate.toIso8601String(),
    };
  }
}
