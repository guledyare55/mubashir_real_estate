import 'property.dart';

class Inquiry {
  final String id;
  final String propertyId;
  final String? customerId; // Linked to authenticated user
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String message;
  final String status;
  final DateTime createdAt;
  final Property? property; 

  Inquiry({
    required this.id,
    required this.propertyId,
    this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.message,
    required this.status,
    required this.createdAt,
    this.property,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String,
      customerEmail: json['customer_email'] as String,
      customerPhone: json['customer_phone'] as String?,
      message: json['message'] as String,
      status: json['status'] as String? ?? 'New',
      createdAt: DateTime.parse(json['created_at']),
      property: json['property'] != null ? Property.fromJson(json['property']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'property_id': propertyId,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      if (customerPhone != null) 'customer_phone': customerPhone,
      'message': message,
      'status': status,
    };
  }
}
