import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../config/theme.dart';

class ContactPickerScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ContactPickerScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<ContactPickerScreen> createState() =>
      _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  List<Contact>? _contacts;
  Map<String, ContactUser> _registeredUsers = {};
  Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Request permission
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Contacts permission denied';
          _isLoading = false;
        });
        return;
      }

      // Load contacts
      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );

      // Extract phone numbers
      final List<String> phones = [];
      for (final contact in contacts) {
        if (contact.phones != null) {
          for (final phone in contact.phones!) {
            if (phone.value != null) {
              phones.add(_cleanPhone(phone.value!));
            }
          }
        }
      }

      // Lookup which contacts are registered
      if (phones.isNotEmpty) {
        final apiService = ref.read(apiServiceProvider);
        final result = await apiService.lookupContacts(phones);

        final users = result['users'] as List;
        _registeredUsers = {};
        for (int i = 0; i < users.length; i++) {
          if (users[i] != null) {
            final user = ContactUser.fromJson(users[i]);
            _registeredUsers[phones[i]] = user;
          }
        }
      }

      setState(() {
        _contacts = contacts.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  ContactUser? _getRegisteredUser(Contact contact) {
    if (contact.phones == null) return null;

    for (final phone in contact.phones!) {
      if (phone.value != null) {
        final cleanPhone = _cleanPhone(phone.value!);
        if (_registeredUsers.containsKey(cleanPhone)) {
          return _registeredUsers[cleanPhone];
        }
      }
    }
    return null;
  }

  List<Contact> get _filteredContacts {
    if (_contacts == null) return [];
    if (_searchQuery.isEmpty) return _contacts!;

    return _contacts!.where((contact) {
      final name = contact.displayName?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _addSelectedContacts() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.addParticipantsToSession(
        sessionId: widget.sessionId,
        userIds: _selectedUserIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add participants: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contacts'),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _addSelectedContacts,
              child: Text(
                'Add (${_selectedUserIds.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadContacts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredContacts.isEmpty
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
                                  _searchQuery.isEmpty
                                      ? 'No contacts found'
                                      : 'No contacts match your search',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              final registeredUser = _getRegisteredUser(contact);
                              final isRegistered = registeredUser != null;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRegistered
                                      ? AppTheme.primary.withOpacity(0.2)
                                      : Colors.grey[300],
                                  child: Text(
                                    (contact.displayName?.isNotEmpty ?? false)
                                        ? contact.displayName![0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isRegistered
                                          ? AppTheme.primary
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(contact.displayName ?? 'Unknown'),
                                subtitle: Text(
                                  isRegistered
                                      ? 'DuTaksim User'
                                      : 'Not registered',
                                  style: TextStyle(
                                    color: isRegistered
                                        ? Colors.green
                                        : Colors.grey[500],
                                  ),
                                ),
                                trailing: isRegistered
                                    ? Checkbox(
                                        value: _selectedUserIds
                                            .contains(registeredUser.id),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked ?? false) {
                                              _selectedUserIds
                                                  .add(registeredUser.id!);
                                            } else {
                                              _selectedUserIds
                                                  .remove(registeredUser.id);
                                            }
                                          });
                                        },
                                      )
                                    : TextButton(
                                        onPressed: () {
                                          // TODO: Implement SMS invitation
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'SMS invitations coming soon'),
                                            ),
                                          );
                                        },
                                        child: const Text('Invite'),
                                      ),
                                onTap: isRegistered
                                    ? () {
                                        setState(() {
                                          if (_selectedUserIds
                                              .contains(registeredUser.id)) {
                                            _selectedUserIds
                                                .remove(registeredUser.id);
                                          } else {
                                            _selectedUserIds
                                                .add(registeredUser.id!);
                                          }
                                        });
                                      }
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
