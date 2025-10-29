import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../models/bill_item.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<User> _participants = [];
  final List<BillItem> _items = [];
  double _tips = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add current user as participant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && !_participants.contains(currentUser)) {
        setState(() => _participants.add(currentUser));
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) return;

      setState(() => _isLoading = true);

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Parse recognized text to extract items
      final parsedItems = _parseReceiptText(recognizedText.text);

      setState(() {
        _items.addAll(parsedItems);
        _isLoading = false;
      });

      await textRecognizer.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${parsedItems.length} items'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning receipt: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  List<BillItem> _parseReceiptText(String text) {
    final items = <BillItem>[];
    final lines = text.split('\n');

    // Simple parsing: look for lines with numbers (prices)
    final pricePattern = RegExp(r'(\d+\.?\d*)');

    for (final line in lines) {
      final matches = pricePattern.allMatches(line);
      if (matches.isNotEmpty) {
        final priceMatch = matches.last;
        final price = double.tryParse(priceMatch.group(0) ?? '');

        if (price != null && price > 0 && price < 10000) {
          final name = line.substring(0, priceMatch.start).trim();
          if (name.isNotEmpty && name.length > 2) {
            items.add(BillItem(
              name: name,
              price: price,
              isShared: false,
              participantIds: [],
            ));
          }
        }
      }
    }

    return items;
  }

  Future<void> _addParticipant() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'phone': phoneController.text,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.isNotEmpty && result['phone']!.isNotEmpty) {
      try {
        final user = await ref.read(apiServiceProvider).registerUser(
              result['name']!,
              result['phone']!,
            );
        setState(() => _participants.add(user));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding participant: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    bool isShared = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  suffixText: 'TJS',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Shared by all'),
                value: isShared,
                onChanged: (value) {
                  setDialogState(() => isShared = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final price = double.tryParse(priceController.text);
                if (nameController.text.isNotEmpty && price != null) {
                  Navigator.pop(context, {
                    'name': nameController.text,
                    'price': price,
                    'isShared': isShared,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _items.add(BillItem(
          name: result['name'],
          price: result['price'],
          isShared: result['isShared'],
          participantIds: [],
        ));
      });
    }
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.price) + _tips;
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one participant')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider)!;
      final apiService = ref.read(apiServiceProvider);

      final bill = await apiService.createBill(
        title: _titleController.text,
        description: _descriptionController.text,
        totalAmount: _totalAmount,
        paidBy: currentUser.id,
        tips: _tips,
        participants: _participants.map((p) => p.id).toList(),
        items: _items.map((item) => {
          'name': item.name,
          'price': item.price,
          'isShared': item.isShared,
          'participants': item.participantIds,
        }).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/bill/${bill.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bill: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bill Info
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Title',
                      hintText: 'Lunch at Restaurant',
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Participants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants (${_participants.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: AppTheme.primary,
                        onPressed: _addParticipant,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ..._participants.map((p) => ListTile(
                        leading: CircleAvatar(
                          child: Text(p.name[0].toUpperCase()),
                        ),
                        title: Text(p.name),
                        subtitle: Text(p.phone),
                      )),

                  const SizedBox(height: 24),

                  // Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items (${_items.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            color: AppTheme.secondary,
                            onPressed: _scanReceipt,
                            tooltip: 'Scan Receipt',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: AppTheme.primary,
                            onPressed: _addItem,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.isShared ? 'Shared' : 'Individual'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.price.toStringAsFixed(2)} TJS',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppTheme.error),
                              onPressed: () => setState(() => _items.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Tips
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tips (Optional)',
                      suffixText: 'TJS',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        _tips = double.tryParse(value) ?? 0;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Total
                  Card(
                    color: AppTheme.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${_totalAmount.toStringAsFixed(2)} TJS',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Create Button
                  ElevatedButton(
                    onPressed: _createBill,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Create Bill'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
