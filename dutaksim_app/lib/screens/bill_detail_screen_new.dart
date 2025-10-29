import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/bill.dart';
import '../models/debt.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../utils/qr_generator.dart';

class BillDetailScreenNew extends ConsumerStatefulWidget {
  final String billId;

  const BillDetailScreenNew({
    super.key,
    required this.billId,
  });

  @override
  ConsumerState<BillDetailScreenNew> createState() => _BillDetailScreenNewState();
}

class _BillDetailScreenNewState extends ConsumerState<BillDetailScreenNew> {
  Bill? _bill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() => _isLoading = true);
    try {
      final bill = await ref.read(apiServiceProvider).getBillById(widget.billId);
      setState(() {
        _bill = bill;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bill: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid(String debtId) async {
    try {
      await ref.read(apiServiceProvider).markDebtAsPaid(debtId);
      await _loadBill();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as paid!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showQRCode(String phone, String name, double amount) {
    final qrData = QRGenerator.generatePaymentQR(phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pay $name'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${amount.toStringAsFixed(2)} TJS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan with Bank Eskhata app',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: Text('Bill not found')),
      );
    }

    final currentUser = ref.watch(currentUserProvider);
    final myDebts = _bill!.debts
            ?.where((d) => d.debtorId == currentUser?.id)
            .toList() ??
        [];
    final debtsToMe = _bill!.debts
            ?.where((d) => d.creditorId == currentUser?.id)
            .toList() ??
        [];
    final allDebts = _bill!.debts ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBill,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBill,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Header with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bill!.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, y • h:mm a').format(_bill!.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paid by',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _bill!.paidByName ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_bill!.totalAmount.toStringAsFixed(2)} TJS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My Debts Section
                    if (myDebts.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.payment,
                        title: 'You Owe',
                        subtitle: '${myDebts.length} ${myDebts.length == 1 ? "debt" : "debts"}',
                      ),
                      const SizedBox(height: 12),
                      ...myDebts.map((debt) => _DebtCard(
                            debt: debt,
                            onPay: () => _showQRCode(
                              debt.creditorPhone!,
                              debt.creditorName!,
                              debt.amount,
                            ),
                            onMarkPaid: () => _markAsPaid(debt.id),
                            isCreditor: false,
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Debts to Me Section
                    if (debtsToMe.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.account_balance_wallet,
                        title: 'Owed to You',
                        subtitle: '${debtsToMe.length} ${debtsToMe.length == 1 ? "debt" : "debts"}',
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 12),
                      ...debtsToMe.map((debt) => _DebtCard(
                            debt: debt,
                            onMarkPaid: () => _markAsPaid(debt.id),
                            isCreditor: true,
                          )),
                      const SizedBox(height: 24),
                    ],

                    // All Debts Overview Section
                    if (allDebts.isNotEmpty &&
                        (allDebts.length > myDebts.length + debtsToMe.length)) ...[
                      _SectionHeader(
                        icon: Icons.list_alt,
                        title: 'All Debts',
                        subtitle: '${allDebts.length} total',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      ...allDebts
                          .where((debt) =>
                              debt.debtorId != currentUser?.id &&
                              debt.creditorId != currentUser?.id)
                          .map((debt) => _DebtCard(
                                debt: debt,
                                onMarkPaid: () => _markAsPaid(debt.id),
                                isCreditor: false,
                                isThirdParty: true,
                              )),
                      const SizedBox(height: 24),
                    ],

                    // Items Section
                    _SectionHeader(
                      icon: Icons.receipt_long,
                      title: 'Items',
                      subtitle: '${_bill!.items?.length ?? 0} items',
                    ),
                    const SizedBox(height: 12),
                    ...(_bill!.items ?? []).map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${item.price.toStringAsFixed(2)} TJS',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (item.isShared) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.group, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Shared by all participants',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (item.participants != null && item.participants!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Split by ${item.participants!.length}:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: item.participants!.map((p) {
                                      return Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                                          child: Text(
                                            p.name[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        label: Text(p.name),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),

                    if (_bill!.tips > 0) ...[
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        color: AppTheme.secondary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.volunteer_activism, color: AppTheme.secondary),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tips',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Shared by all',
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_bill!.tips.toStringAsFixed(2)} TJS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Participants Section
                    _SectionHeader(
                      icon: Icons.people,
                      title: 'Participants',
                      subtitle: '${_bill!.participants?.length ?? 0} people',
                    ),
                    const SizedBox(height: 12),
                    ...(_bill!.participants ?? []).map((participant) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                participant.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(participant.name),
                            subtitle: Text(participant.phone),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onPay;
  final VoidCallback onMarkPaid;
  final bool isCreditor;
  final bool isThirdParty;

  const _DebtCard({
    required this.debt,
    this.onPay,
    required this.onMarkPaid,
    required this.isCreditor,
    this.isThirdParty = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.isPaid;
    final cardColor = isPaid
        ? Colors.grey.withOpacity(0.05)
        : (isThirdParty
            ? Colors.blue.withOpacity(0.05)
            : (isCreditor
                ? AppTheme.success.withOpacity(0.05)
                : AppTheme.error.withOpacity(0.05)));

    final avatarColor = isPaid
        ? Colors.grey
        : (isThirdParty
            ? Colors.blue
            : (isCreditor ? AppTheme.success : AppTheme.error));

    String debtText;
    if (isThirdParty) {
      debtText = '${debt.debtorName ?? "Unknown"} owes ${debt.creditorName ?? "Unknown"}';
    } else if (isCreditor) {
      debtText = '${debt.debtorName ?? "Unknown"} owes you';
    } else {
      debtText = 'You owe ${debt.creditorName ?? "Unknown"}';
    }

    return Card(
      elevation: isPaid ? 1 : 3,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: avatarColor,
                      child: Icon(
                        isPaid
                            ? Icons.check_circle
                            : (isCreditor ? Icons.arrow_downward : Icons.arrow_upward),
                        color: Colors.white,
                      ),
                    ),
                    if (isPaid)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              debtText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: isPaid ? TextDecoration.lineThrough : null,
                                color: isPaid ? Colors.grey : null,
                              ),
                            ),
                          ),
                          if (isPaid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PAID',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isThirdParty
                            ? '${debt.debtorPhone ?? ""} → ${debt.creditorPhone ?? ""}'
                            : (isCreditor ? debt.debtorPhone ?? '' : debt.creditorPhone ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isPaid && debt.paidAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Paid on ${DateFormat('MMM d, y').format(debt.paidAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${debt.amount.toStringAsFixed(2)} TJS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.grey
                        : (isThirdParty
                            ? Colors.blue
                            : (isCreditor ? AppTheme.success : AppTheme.error)),
                    decoration: isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            if (!isPaid && !isCreditor && !isThirdParty && onPay != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Pay with QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Paid'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
