import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/time_utils.dart';
import '../../domain/endorsement_document.dart';
import '../providers/endorsements_providers.dart';
import 'image_loader/endorsement_image_loader.dart';

class EndorsementDetailsDialog extends ConsumerStatefulWidget {
  final EndorsementDocument document;
  final void Function(EndorsementDocument document)? onSupersede;

  const EndorsementDetailsDialog({
    super.key,
    required this.document,
    this.onSupersede,
  });

  @override
  ConsumerState<EndorsementDetailsDialog> createState() => _EndorsementDetailsDialogState();
}

class _EndorsementDetailsDialogState extends ConsumerState<EndorsementDetailsDialog> {
  bool _isVerifying = false;
  bool? _integrityResult;

  Future<void> _verifyIntegrity() async {
    setState(() {
      _isVerifying = true;
      _integrityResult = null;
    });

    try {
      final repo = ref.read(endorsementsRepositoryProvider);
      final isIntact = await repo.verifyIntegrity(widget.document.id);
      if (mounted) {
        setState(() {
          _integrityResult = isIntact;
          _isVerifying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _integrityResult = false;
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Endorsement?'),
        content: const Text(
          'Are you sure you want to delete this endorsement scan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(endorsementsRepositoryProvider);
      await repo.deleteEndorsement(widget.document.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endorsement document deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = TimeUtils.formatDateFull(doc.endorsementDate);


    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.category.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Endorsed: $formattedDate${doc.pageNumber != null ? ' • Page ${doc.pageNumber}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Zoomable Image Preview
            Expanded(
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Center(
                    child: defaultImageLoader.buildImage(
                      doc.originalPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Metadata & Integrity section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Banners
                  if (doc.isSuperseded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        border: Border.all(color: Colors.amber.shade600),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.amber.shade900, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Superseded by replacement document #${doc.supersededBy}',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (doc.isReplacement)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.published_with_changes, color: Colors.blue.shade800, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Replaces older document #${doc.supersedes}',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                    Text(
                      'Notes: ${doc.notes}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // SHA-256 Checksum Container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fingerprint, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'SHA-256 Checksum',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy SHA-256',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: doc.sha256));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('SHA-256 copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        SelectableText(
                          doc.sha256,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Live verify button
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isVerifying ? null : _verifyIntegrity,
                              icon: _isVerifying
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.verified, size: 16),
                              label: Text(_isVerifying ? 'Verifying...' : 'Verify Integrity'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                            if (_integrityResult == true)
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Intact',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else if (_integrityResult == false)
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hash Mismatch / Corrupted',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Actions row
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: _deleteDocument,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                      ),
                      if (!doc.isSuperseded && widget.onSupersede != null)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onSupersede!(doc);
                          },
                          icon: const Icon(Icons.upgrade, size: 18),
                          label: const Text('Supersede / Replace Scan'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
