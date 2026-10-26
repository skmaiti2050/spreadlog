import 'package:flutter/material.dart';

import '../database/connection/storage_status.dart';

/// Warns when the database cannot persist: on web, drift falls back to an
/// in-memory database if the browser blocks every storage API (some private
/// windows, disabled site data), and everything vanishes on reload.
class StorageWarningBanner extends StatelessWidget {
  const StorageWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StorageStatus?>(
      valueListenable: storageStatus,
      builder: (context, status, _) {
        if (status == null || status.isPersistent) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: scheme.errorContainer,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This browser is not letting Spreadlog save data, so '
                    'entries will be lost when the page closes. Leave '
                    'private browsing or allow site data, or use the app.',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
