import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../config/theme.dart';
import '../models/session.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _tipsController = TextEditingController(text: '0');
  String? _selectedForUser;
  bool _isShared = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _itemNameController.text.trim();
    final priceText = _itemPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item name and price')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    try {
      await ref.read(sessionNotifierProvider.notifier).addItem(
            name: name,
            price: price,
            addedBy: user.id,
            forUserId: _isShared ? null : _selectedForUser,
            isShared: _isShared,
          );

      _itemNameController.clear();
      _itemPriceController.clear();
      setState(() {
        _selectedForUser = null;
        _isShared = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await ref.read(sessionNotifierProvider.notifier).deleteItem(itemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $e')),
        );
      }
    }
  }

  Future<void> _finalizeSession(BillSession session) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Show dialog to select who paid
    final paidBy = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who paid?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the person who paid the bill:'),
            const SizedBox(height: 16),
            ...session.participants.map((p) => RadioListTile<String>(
                  title: Text(p.name),
                  value: p.id,
                  groupValue: user.id,
                  onChanged: (value) => Navigator.pop(context, value),
                )),
          ],
        ),
      ),
    );

    if (paidBy == null) return;

    final tips = double.tryParse(_tipsController.text) ?? 0;

    try {
      final billId = await ref
          .read(sessionNotifierProvider.notifier)
          .finalizeSession(
            title: session.name,
            paidBy: paidBy,
            tips: tips,
          );

      if (mounted) {
        context.go('/bill/$billId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finalize: $e')),
        );
      }
    }
  }

  void _showQRCode(String sessionCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session QR Code'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                color: Colors.white,
                child: QrImageView(
                  data: sessionCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Code: $sessionCode',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sessionCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
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
    final sessionAsync = ref.watch(sessionNotifierProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborative Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(sessionNotifierProvider.notifier).refreshSession();
            },
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('No active session'));
          }

          final isCreator =
              session.participants.any((p) => p.id == user?.id && p.isCreator);

          return Column(
            children: [
              // Header with session info
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.secondary.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.participants.length} participants',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => _showQRCode(session.sessionCode),
                          icon: const Icon(Icons.qr_code),
                          tooltip: 'Show QR Code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${session.totalAmount.toStringAsFixed(2)} с.',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: session.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add items below',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: session.items.length,
                        itemBuilder: (context, index) {
                          final item = session.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  item.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                item.isShared
                                    ? 'Shared'
                                    : item.forUserName != null
                                        ? 'For ${item.forUserName}'
                                        : 'Added by ${item.addedByName}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${item.price.toStringAsFixed(2)} с.',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.addedBy == user?.id ||
                                      isCreator) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteItem(item.id),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Add item section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _itemNameController,
                            decoration: const InputDecoration(
                              labelText: 'Item name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _itemPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Shared'),
                            value: _isShared,
                            onChanged: (value) {
                              setState(() {
                                _isShared = value ?? false;
                                if (_isShared) _selectedForUser = null;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (!_isShared)
                          Expanded(
                            child: DropdownButton<String>(
                              hint: const Text('For whom?'),
                              value: _selectedForUser,
                              isExpanded: true,
                              items: session.participants.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedForUser = value);
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: session.items.isEmpty
                                  ? null
                                  : () => _finalizeSession(session),
                              icon: const Icon(Icons.check),
                              label: const Text('Finalize'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isCreator && session.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tipsController,
                        decoration: const InputDecoration(
                          labelText: 'Tips (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
