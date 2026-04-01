import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String userId;
  final String name;
  final double price;
  final String billingCycle;
  final DateTime nextBillingDate;
  final String category;
  final String? notes;
  final String status;
  final DateTime createdAt;

  Subscription({
    String? id,
    required this.userId,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.category,
    this.notes,
    required this.status,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: (json['id'] ?? json['ID'] ?? json['uuid'])?.toString(),
      userId: json['user_id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      billingCycle: json['billing_cycle'],
      nextBillingDate: DateTime.parse(json['next_billing_date']),
      category: json['category'],
      notes: json['notes'],
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'price': price,
      'billing_cycle': billingCycle,
      'next_billing_date': nextBillingDate.toIso8601String().split('T').first,
      'category': category,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Subscription copyWith({
    String? name,
    double? price,
    String? billingCycle,
    DateTime? nextBillingDate,
    String? category,
    String? notes,
    String? status,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      name: name ?? this.name,
      price: price ?? this.price,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
