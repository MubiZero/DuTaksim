import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/user_provider.dart';
import '../providers/bill_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: const Color(0xFF0A1929),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A1929),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(billsProvider);
        },
        child: billsAsync.when(
          data: (bills) {
            if (bills.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withOpacity(0.1),
                              AppTheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          size: 80,
                          color: AppTheme.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'No bills yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create your first bill to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bill = bills[index];
                final user = ref.watch(userNotifierProvider);
                final isPaidByMe = bill.paidBy == user?.id;

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/bill/${bill.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E3A5F),
                            const Color(0xFF132943),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPaidByMe
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    bill.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPaidByMe
                                        ? AppTheme.success.withOpacity(0.2)
                                        : AppTheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isPaidByMe ? AppTheme.success : AppTheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isPaidByMe ? 'Paid by me' : 'Paid by ${bill.paidByName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isPaidByMe ? AppTheme.success : AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y • h:mm a').format(bill.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary.withOpacity(0.15),
                                    AppTheme.primary.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          size: 20,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Total Amount',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${bill.totalAmount.toStringAsFixed(2)} TJS',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading bills',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
