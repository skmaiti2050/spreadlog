import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/hints/hints_service.dart';
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
    final theme = Theme.of(context);
    final hintsState = ref.watch(hintsProvider);

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'These credentials are automatically applied to your official Logbook PDF, Career Summary Slip, and flight logs.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                  labelText: 'Licence Number',
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Operational Hints & Gestures Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Show Operational Hints',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: hintsState.hintsEnabled,
                    onChanged: (val) => ref.read(hintsProvider.notifier).setHintsEnabled(val),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Dismissed Hints'),
                onPressed: () async {
                  await ref.read(hintsProvider.notifier).resetAllHints();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All operational hints have been reset')),
                    );
                  }
                },
              ),
            ],
          ),
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

