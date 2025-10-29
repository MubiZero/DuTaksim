import 'user.dart';
import 'bill_item.dart';
import 'debt.dart';

class Bill {
  final String id;
  final String title;
  final String? description;
  final double totalAmount;
  final String paidBy;
  final double tips;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Populated fields
  final String? paidByName;
  final String? paidByPhone;
  final List<User>? participants;
  final List<BillItem>? items;
  final List<Debt>? debts;

  Bill({
    required this.id,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.paidBy,
    this.tips = 0,
    required this.createdAt,
    this.updatedAt,
    this.paidByName,
    this.paidByPhone,
    this.participants,
    this.items,
    this.debts,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmount: double.parse(json['total_amount'].toString()),
      paidBy: json['paid_by'] as String,
      tips: double.parse(json['tips']?.toString() ?? '0'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      paidByName: json['paid_by_name'] as String?,
      paidByPhone: json['paid_by_phone'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => BillItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      debts: (json['debts'] as List<dynamic>?)
          ?.map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'total_amount': totalAmount,
      'paid_by': paidBy,
      'tips': tips,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (paidByName != null) 'paid_by_name': paidByName,
      if (paidByPhone != null) 'paid_by_phone': paidByPhone,
      if (participants != null)
        'participants': participants!.map((e) => e.toJson()).toList(),
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      if (debts != null) 'debts': debts!.map((e) => e.toJson()).toList(),
    };
  }
}
