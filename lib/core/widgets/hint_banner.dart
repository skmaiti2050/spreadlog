import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hints/hints_service.dart';

/// Lightweight, non-intrusive in-situ hint banner with aviation styling.
/// Displays actionable gestures and regulatory tips, remembering dismissal.
class HintBanner extends ConsumerWidget {
  final String hintKey;
  final String message;
  final IconData icon;
  final EdgeInsetsGeometry margin;

  const HintBanner({
    super.key,
    required this.hintKey,
    required this.message,
    this.icon = Icons.lightbulb_outline,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hints = ref.watch(hintsProvider);
    if (!hints.isVisible(hintKey)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => ref.read(hintsProvider.notifier).dismiss(hintKey),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Got it',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

