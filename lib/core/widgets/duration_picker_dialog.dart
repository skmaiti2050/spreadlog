import 'package:flutter/material.dart';

import '../utils/time_utils.dart';

/// Interactive modal bottom sheet / dialog for selecting flight duration (Hours : Minutes)
/// without requiring manual keyboard typing.
class DurationPickerDialog extends StatefulWidget {
  final int initialMinutes;
  final String title;

  const DurationPickerDialog({
    super.key,
    required this.initialMinutes,
    this.title = 'Select Flight Duration',
  });

  /// Shows the duration picker as a modal bottom sheet on mobile or dialog on wide screens.
  static Future<int?> show(
    BuildContext context, {
    required int initialMinutes,
    String title = 'Select Flight Duration',
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => DurationPickerDialog(
          initialMinutes: initialMinutes,
          title: title,
        ),
      );
    }
    return showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DurationPickerDialog(
              initialMinutes: initialMinutes,
              title: title,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _hours;
  late int _minutes;

  static const List<int> _popularPresetsMinutes = [
    30, // 0:30
    45, // 0:45
    60, // 1:00
    75, // 1:15
    90, // 1:30
    105, // 1:45
    120, // 2:00
    150, // 2:30
    180, // 3:00
  ];

  @override
  void initState() {
    super.initState();
    final clamped = widget.initialMinutes > 0 ? widget.initialMinutes : 90; // Default 1h 30m
    _hours = (clamped ~/ 60).clamp(0, 99);
    _minutes = (clamped % 60).clamp(0, 59);
  }

  int get _totalMinutes => (_hours * 60) + _minutes;

  void _adjustHours(int delta) {
    setState(() {
      _hours = (_hours + delta).clamp(0, 99);
    });
  }

  void _adjustMinutes(int delta) {
    setState(() {
      int total = _totalMinutes + delta;
      if (total < 0) total = 0;
      _hours = (total ~/ 60).clamp(0, 99);
      _minutes = total % 60;
    });
  }

  void _setMinutes(int mins) {
    setState(() {
      _hours = mins ~/ 60;
      _minutes = mins % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalMins = _totalMinutes;
    final hhMm = TimeUtils.formatMinutesToHhMm(totalMins);
    final decimalHours = TimeUtils.formatMinutesToDecimal(totalMins);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Big Display & Spinner Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours Stepper
                  _buildStepperColumn(
                    label: 'HOURS',
                    value: _hours.toString().padLeft(2, '0'),
                    onIncrement: () => _adjustHours(1),
                    onDecrement: () => _adjustHours(-1),
                    theme: theme,
                  ),

                  // Colon Separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  // Minutes Stepper
                  _buildStepperColumn(
                    label: 'MINUTES',
                    value: _minutes.toString().padLeft(2, '0'),
                    onIncrement: () => _adjustMinutes(5),
                    onDecrement: () => _adjustMinutes(-5),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Total readout banner
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Total: $hhMm ($decimalHours hrs)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Delta Adjustment Chips
            Text(
              'Quick Adjust',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _adjustChip('+5m', 5, colorScheme),
                _adjustChip('+10m', 10, colorScheme),
                _adjustChip('+15m', 15, colorScheme),
                _adjustChip('+30m', 30, colorScheme),
                _adjustChip('+1h', 60, colorScheme),
                _adjustChip('-5m', -5, colorScheme),
                _adjustChip('-15m', -15, colorScheme),
              ],
            ),
            const SizedBox(height: 10),

            // Common Flight Presets
            Text(
              'Flight Presets',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularPresetsMinutes.map((mins) {
                final isSelected = totalMins == mins;
                final label = TimeUtils.formatMinutesToHhMm(mins);
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onSelected: (_) => _setMinutes(mins),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Confirm Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Set Duration ($hhMm)'),
                    onPressed: () => Navigator.of(context).pop(_totalMinutes),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperColumn({
    required String label,
    required String value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        IconButton.filledTonal(
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onIncrement,
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onDecrement,
        ),
      ],
    );
  }

  Widget _adjustChip(String label, int delta, ColorScheme colorScheme) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: () => _adjustMinutes(delta),
    );
  }
}
