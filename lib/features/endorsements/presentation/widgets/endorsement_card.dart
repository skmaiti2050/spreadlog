import 'package:flutter/material.dart';

import '../../../../core/utils/time_utils.dart';
import '../../domain/endorsement_category.dart';
import '../../domain/endorsement_document.dart';
import 'image_loader/endorsement_image_loader.dart';

class EndorsementCard extends StatelessWidget {
  final EndorsementDocument document;
  final VoidCallback onTap;

  const EndorsementCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final shortSha = document.sha256.length > 12
        ? '${document.sha256.substring(0, 6)}...${document.sha256.substring(document.sha256.length - 6)}'
        : document.sha256;

    final formattedDate = TimeUtils.formatDate(document.endorsementDate);

    return Card(
      elevation: document.isSuperseded ? 0.5 : 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: document.isSuperseded
              ? colorScheme.outline.withAlpha(40)
              : colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Box
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 100,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      defaultImageLoader.buildImage(
                        document.originalPath,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 100,
                      ),
                      if (document.isSuperseded)
                        Container(
                          color: Colors.black.withAlpha(120),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SUPERSEDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildCategoryChip(context, document.category),
                        const Spacer(),
                        if (document.pageNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pg. ${document.pageNumber}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: document.isSuperseded ? colorScheme.onSurface.withAlpha(140) : null,
                      ),
                    ),
                    if (document.notes != null && document.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        document.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Tamper-proof SHA badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.teal.shade900.withAlpha(120) : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.teal.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SHA: $shortSha',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, EndorsementCategory category) {
    final theme = Theme.of(context);
    final color = _getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        category.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(EndorsementCategory cat) {
    switch (cat) {
      case EndorsementCategory.vp:
        return Colors.blue;
      case EndorsementCategory.ru:
        return Colors.deepPurple;
      case EndorsementCategory.t:
        return Colors.orange.shade800;
      case EndorsementCategory.p:
        return Colors.indigo;
      case EndorsementCategory.tw:
        return Colors.brown;
      case EndorsementCategory.nightRating:
        return Colors.deepPurple.shade700;
      case EndorsementCategory.instrumentRating:
        return Colors.green.shade700;
      case EndorsementCategory.modelRegister:
        return Colors.teal;
      case EndorsementCategory.general:
      case EndorsementCategory.other:
        return Colors.blueGrey;
    }
  }
}

