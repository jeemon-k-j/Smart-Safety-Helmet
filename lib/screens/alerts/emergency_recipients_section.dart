import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../repositories/emergency_contact_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/email_validation.dart';

/// Emergency email recipient configuration (not a separate Contacts tab).
class EmergencyRecipientsSection extends StatefulWidget {
  const EmergencyRecipientsSection({super.key, required this.repository});

  final EmergencyContactRepository repository;

  @override
  State<EmergencyRecipientsSection> createState() =>
      _EmergencyRecipientsSectionState();
}

class _EmergencyRecipientsSectionState
    extends State<EmergencyRecipientsSection> {
  Future<void> _addRecipient() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add alert recipient'),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      isValidEmergencyEmail(v) ? null : 'Valid email required',
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
            SnackBar(content: Text('Could not save recipient: $error')),
          );
        }
      }
    }
    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Alert recipients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _addRecipient,
              icon: const Icon(Icons.add),
              label: const Text('Add email'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'These addresses receive accident emergency emails after the '
          'countdown, unless the rider cancels.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.unknown,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<EmergencyContact>>(
          stream: widget.repository.watchContacts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final contacts = snapshot.data;
            if (contacts == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (contacts.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No recipients yet. Add at least one email so accident '
                    'alerts can be delivered.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.unknown,
                          height: 1.4,
                        ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < contacts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.safeSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.mail_outline,
                          color: AppColors.safe,
                        ),
                      ),
                      title: Text(
                        contacts[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(contacts[i].email),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            widget.repository.removeContact(contacts[i].id),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
