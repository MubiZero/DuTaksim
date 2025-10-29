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

class BillDetailScreen extends ConsumerStatefulWidget {
  final String billId;

  const BillDetailScreen({
    super.key,
    required this.billId,
  });

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              '${amount.toStringAsFixed(2)} TJS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan with Bank Eskhata app',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
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
            ?.where((d) => d.debtorId == currentUser?.id && !d.isPaid)
            .toList() ??
        [];
    final debtsToMe = _bill!.debts
            ?.where((d) => d.creditorId == currentUser?.id && !d.isPaid)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBill,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bill Header
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bill!.title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (_bill!.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        _bill!.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid by',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _bill!.paidByName ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${_bill!.totalAmount.toStringAsFixed(2)} TJS',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMMM d, y \'at\' h:mm a').format(_bill!.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // My Debts
            if (myDebts.isNotEmpty) ...[
              Text(
                'You Owe',
                style: Theme.of(context).textTheme.titleLarge,
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

            // Debts to Me
            if (debtsToMe.isNotEmpty) ...[
              Text(
                'Owed to You',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...debtsToMe.map((debt) => _DebtCard(
                    debt: debt,
                    onMarkPaid: () => _markAsPaid(debt.id),
                    isCreditor: true,
                  )),
              const SizedBox(height: 24),
            ],

            // Items
            Text(
              'Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...(_bill!.items ?? []).map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      item.isShared
                          ? 'Shared by all'
                          : 'Split by ${item.participants?.length ?? 0} people',
                    ),
                    trailing: Text(
                      '${item.price.toStringAsFixed(2)} TJS',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )),

            if (_bill!.tips > 0) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Tips'),
                  subtitle: const Text('Shared by all'),
                  trailing: Text(
                    '${_bill!.tips.toStringAsFixed(2)} TJS',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Participants
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...(_bill!.participants ?? []).map((participant) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondary,
                      child: Text(
                        participant.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(participant.name),
                    subtitle: Text(participant.phone),
                  ),
                )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onPay;
  final VoidCallback onMarkPaid;
  final bool isCreditor;

  const _DebtCard({
    required this.debt,
    this.onPay,
    required this.onMarkPaid,
    required this.isCreditor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCreditor ? debt.debtorName! : debt.creditorName!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        isCreditor ? debt.debtorPhone! : debt.creditorPhone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${debt.amount.toStringAsFixed(2)} TJS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isCreditor ? AppTheme.success : AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isCreditor && onPay != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                if (!isCreditor && onPay != null) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMarkPaid,
                    child: const Text('Mark as Paid'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
