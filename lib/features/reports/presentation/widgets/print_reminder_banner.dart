import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flights/presentation/providers/flights_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../pdf_preview_screen.dart';
import '../providers/print_reminder_providers.dart';

/// Prompts for the paper copy SACAA requires every 90 days. "Later" hides
/// it until the screen is rebuilt from scratch; printing or sharing the PDF
/// clears it for the next 90 days.
class PrintReminderBanner extends ConsumerStatefulWidget {
  const PrintReminderBanner({super.key});

  @override
  ConsumerState<PrintReminderBanner> createState() =>
      _PrintReminderBannerState();
}

class _PrintReminderBannerState extends ConsumerState<PrintReminderBanner> {
  bool _snoozed = false;

  @override
  Widget build(BuildContext context) {
    if (_snoozed || !ref.watch(printReminderDueProvider)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print_outlined, color: scheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Time to print your logbook. SACAA requires electronic '
                    'logbooks to be printed at least every 90 days and '
                    'filed in order.',
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _snoozed = true),
                    child: const Text('Later'),
                  ),
                  FilledButton.tonal(
                    onPressed: _openPdf,
                    child: const Text('Print now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf() {
    final profile = ref.read(pilotProfileProvider);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          pages: ref.read(ledgerPagesProvider),
          pilotName: profile.pilotName,
          licenceNumber: profile.licenceNumber,
        ),
      ),
    );
  }
}
