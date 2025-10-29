import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    print('QR Scanner - Detected code: $code');
    await _joinSessionWithCode(code);
  }

  Future<void> _joinSessionWithCode(String code) async {
    if (_isProcessing) {
      print('QR Scanner - Already processing, ignoring');
      return;
    }

    setState(() => _isProcessing = true);
    print('QR Scanner - Starting join process');

    try {
      final user = ref.read(currentUserProvider);
      print('QR Scanner - Current user: ${user?.id} (${user?.name})');

      if (user == null) {
        throw Exception('User not logged in');
      }

      print('QR Scanner - Calling joinSession with code: $code');

      // Try to join session
      await ref.read(sessionNotifierProvider.notifier).joinSession(
            sessionCode: code,
            userId: user.id,
          );

      print('QR Scanner - Successfully joined session');

      // Navigate only after successful join
      if (mounted) {
        print('QR Scanner - Navigating to session screen');
        context.go('/session');
      }
    } catch (e, stackTrace) {
      print('QR Scanner - Error joining session: $e');
      print('QR Scanner - Stack trace: $stackTrace');

      // Only show error if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join session: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_controller.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the QR code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Manual code entry button
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: _showManualEntry,
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Enter code manually',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Session Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Code',
            hintText: 'ABC123',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isEmpty) return;

              print('Manual entry - Code entered: $code');

              // Close dialog first
              if (mounted) {
                Navigator.pop(context);
              }

              // Use the same method as QR scanning
              await _joinSessionWithCode(code);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
