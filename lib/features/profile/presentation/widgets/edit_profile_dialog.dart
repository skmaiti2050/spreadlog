import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_providers.dart';

/// Modal dialog for viewing and updating Pilot Profile credentials.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _licenceController;
  late final TextEditingController _picController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(pilotProfileProvider);
    _nameController = TextEditingController(text: profile.pilotName);
    _licenceController = TextEditingController(text: profile.licenceNumber);
    _picController = TextEditingController(text: profile.defaultPicName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenceController.dispose();
    _picController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(pilotProfileProvider.notifier).updateProfile(
          pilotName: _nameController.text,
          licenceNumber: _licenceController.text,
          defaultPicName: _picController.text.trim().isNotEmpty
              ? _picController.text.trim()
              : 'SELF',
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilot Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.badge_outlined),
          SizedBox(width: 8),
          Text('Pilot Profile'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'These credentials are automatically applied to your official SACAA Logbook PDF, Career Summary Slip, and flight logs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pilot Full Name',
                hintText: 'e.g. CAPT J. DOE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licenceController,
              decoration: const InputDecoration(
                labelText: 'SACAA Licence Number',
                hintText: 'e.g. ZA-123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _picController,
              decoration: const InputDecoration(
                labelText: 'Default PIC Name',
                hintText: 'e.g. SELF or CAPT DOE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flight_takeoff_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Profile'),
        ),
      ],
    );
  }
}

