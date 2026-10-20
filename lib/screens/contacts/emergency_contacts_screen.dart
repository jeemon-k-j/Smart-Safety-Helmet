import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../repositories/emergency_contact_repository.dart';
import '../../theme/app_theme.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key, required this.repository});

  final EmergencyContactRepository repository;

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add emergency contact'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Valid email required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      try {
        await widget.repository.addContact(
          name: nameController.text,
          email: emailController.text,
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save contact: $error')),
          );
        }
      }
    }
    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: widget.repository.watchContacts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final contacts = snapshot.data;
          if (contacts == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppMetrics.page),
                child: Text(
                  'No emergency contacts yet. Add email addresses that should receive accident alerts.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppMetrics.page),
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.email_outlined)),
                  title: Text(contact.name),
                  subtitle: Text(contact.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => widget.repository.removeContact(contact.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
