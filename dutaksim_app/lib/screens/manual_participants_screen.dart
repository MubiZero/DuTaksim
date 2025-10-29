import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/user.dart';

enum InputMode {
  contacts, // From phone contacts
  manual, // Manual phone number entry
}

class ManualParticipantsScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String sessionName;

  const ManualParticipantsScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  ConsumerState<ManualParticipantsScreen> createState() =>
      _ManualParticipantsScreenState();
}

class _ManualParticipantsScreenState
    extends ConsumerState<ManualParticipantsScreen> {
  InputMode _inputMode = InputMode.contacts;
  final List<User> _selectedParticipants = [];
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addManualParticipant() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required')),
      );
      return;
    }

    // Check if already added
    if (_selectedParticipants.any((p) => p.phone == phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant already added')),
      );
      return;
    }

    setState(() {
      _selectedParticipants.add(User(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: name.isEmpty ? phone : name,
        phone: phone,
      ));
      _phoneController.clear();
      _nameController.clear();
    });
  }

  void _removeParticipant(User user) {
    setState(() {
      _selectedParticipants.remove(user);
    });
  }

  Future<void> _confirmParticipants() async {
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one participant')),
      );
      return;
    }

    // TODO: Send participants to backend
    // For now, just navigate to session screen
    if (mounted) {
      context.go('/session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionName),
        actions: [
          if (_selectedParticipants.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmParticipants,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Done (${_selectedParticipants.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode switcher
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ModeSwitchButton(
                    icon: Icons.contacts,
                    label: 'From Contacts',
                    selected: _inputMode == InputMode.contacts,
                    onTap: () => setState(() => _inputMode = InputMode.contacts),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeSwitchButton(
                    icon: Icons.dialpad,
                    label: 'Manual Entry',
                    selected: _inputMode == InputMode.manual,
                    onTap: () => setState(() => _inputMode = InputMode.manual),
                  ),
                ),
              ],
            ),
          ),

          // Input area based on mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: _inputMode == InputMode.contacts
                ? _buildContactsInput()
                : _buildManualInput(),
          ),

          // Selected participants list
          Expanded(
            child: _selectedParticipants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No participants added yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _inputMode == InputMode.contacts
                              ? 'Select from contacts above'
                              : 'Enter phone numbers above',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedParticipants.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final participant = _selectedParticipants[index];
                      return Card(
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
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => _removeParticipant(participant),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedParticipants.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmParticipants,
              icon: const Icon(Icons.check),
              label: Text('Add ${_selectedParticipants.length} Participants'),
            )
          : null,
    );
  }

  Widget _buildContactsInput() {
    // TODO: Implement actual contact picker
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select participants from your contacts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Open contact picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact picker coming soon! Use manual entry for now.'),
              ),
            );
          },
          icon: const Icon(Icons.contacts),
          label: const Text('Open Contacts'),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+992XXXXXXXXX',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name (Optional)',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addManualParticipant,
          icon: const Icon(Icons.add),
          label: const Text('Add Participant'),
        ),
      ],
    );
  }
}

class _ModeSwitchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSwitchButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
