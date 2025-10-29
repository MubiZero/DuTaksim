class Debt {
  final String id;
  final String billId;
  final String debtorId;
  final String creditorId;
  final double amount;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  // Additional info
  final String? debtorName;
  final String? debtorPhone;
  final String? creditorName;
  final String? creditorPhone;
  final String? billTitle;

  Debt({
    required this.id,
    required this.billId,
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    this.isPaid = false,
    this.paidAt,
    required this.createdAt,
    this.debtorName,
    this.debtorPhone,
    this.creditorName,
    this.creditorPhone,
    this.billTitle,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      debtorId: json['debtor_id'] as String,
      creditorId: json['creditor_id'] as String,
      amount: double.parse(json['amount'].toString()),
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      debtorName: json['debtor_name'] as String?,
      debtorPhone: json['debtor_phone'] as String?,
      creditorName: json['creditor_name'] as String?,
      creditorPhone: json['creditor_phone'] as String?,
      billTitle: json['bill_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'debtor_id': debtorId,
      'creditor_id': creditorId,
      'amount': amount,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (debtorName != null) 'debtor_name': debtorName,
      if (debtorPhone != null) 'debtor_phone': debtorPhone,
      if (creditorName != null) 'creditor_name': creditorName,
      if (creditorPhone != null) 'creditor_phone': creditorPhone,
      if (billTitle != null) 'bill_title': billTitle,
    };
  }
}
