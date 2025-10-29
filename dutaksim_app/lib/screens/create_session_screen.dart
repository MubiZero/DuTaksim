import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/session_provider.dart';
import '../providers/user_provider.dart';
import '../config/theme.dart';

enum ParticipantMode {
  room, // QR + geolocation
  manual, // Manual entry (includes contacts)
}

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() =>
      _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _nameController = TextEditingController();
  ParticipantMode _selectedMode = ParticipantMode.room;
  Position? _currentPosition;
  bool _useLocation = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _createSession() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a session name')),
      );
      return;
    }

    Position? position;
    if (_selectedMode == ParticipantMode.room && _useLocation) {
      position = await _getLocation();
      if (position == null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location unavailable'),
            content: const Text(
              'Could not get your location. Create session without location?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    try {
      print('Creating session with:');
      print('  name: $name');
      print('  creatorId: ${user.id}');
      print('  latitude: ${position?.latitude}');
      print('  longitude: ${position?.longitude}');

      await ref.read(sessionNotifierProvider.notifier).createSession(
            name: name,
            creatorId: user.id,
            latitude: position?.latitude,
            longitude: position?.longitude,
          );

      if (mounted) {
        if (_selectedMode == ParticipantMode.room) {
          // Go to session screen for collaborative mode
          context.go('/session');
        } else {
          // Go to manual participants screen
          final sessionAsync = ref.read(sessionNotifierProvider);
          final session = sessionAsync.value;
          if (session != null) {
            context.push('/manual-participants', extra: {
              'sessionId': session.id,
              'sessionName': session.name,
            });
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error creating session: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create session: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'e.g., Lunch at Centro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How do you want to add participants?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Room mode (QR + geo)
            _ModeCard(
              icon: Icons.location_on,
              iconColor: AppTheme.primary,
              title: 'Create Room',
              subtitle:
                  'Generate QR code and let nearby people join automatically',
              selected: _selectedMode == ParticipantMode.room,
              onTap: () => setState(() => _selectedMode = ParticipantMode.room),
              badge: 'RECOMMENDED',
              badgeColor: Colors.green,
            ),

            const SizedBox(height: 12),

            // Manual mode (includes contacts)
            _ModeCard(
              icon: Icons.edit,
              iconColor: Colors.purple,
              title: 'Manual Entry',
              subtitle: 'Add participants from contacts or enter manually',
              selected: _selectedMode == ParticipantMode.manual,
              onTap: () =>
                  setState(() => _selectedMode = ParticipantMode.manual),
            ),

            const SizedBox(height: 24),

            // Location toggle for room mode
            if (_selectedMode == ParticipantMode.room) ...[
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.gps_fixed),
                  title: const Text('Enable GPS Discovery'),
                  subtitle: const Text(
                    'Others nearby can find and join your session',
                  ),
                  value: _useLocation,
                  onChanged: (value) => setState(() => _useLocation = value),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info cards based on mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedMode == ParticipantMode.room) ...[
                    _InfoPoint('Generate a QR code for others to scan'),
                    _InfoPoint('Nearby sessions appear in "Find Room" screen'),
                    _InfoPoint('Everyone can add their items in real-time'),
                    _InfoPoint('Creator finalizes and splits the bill'),
                  ] else ...[
                    _InfoPoint('Choose participants from your contacts'),
                    _InfoPoint('Or enter phone numbers manually'),
                    _InfoPoint('Add items on their behalf'),
                    _InfoPoint('Best for small groups'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _createSession,
              icon: const Icon(Icons.add_circle),
              label: const Text('Create Session'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final String text;

  const _InfoPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
