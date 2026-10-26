import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../endorsements/presentation/providers/endorsements_providers.dart';
import '../../../endorsements/presentation/widgets/scan_endorsement_dialog.dart';
import '../../domain/aircraft_model.dart';
import '../../domain/model_endorsement.dart';
import '../providers/aircraft_providers.dart';

class EndorseAircraftDialog extends ConsumerStatefulWidget {
  final AircraftModel? initialModel;
  final ModelEndorsement? initialEndorsement;

  const EndorseAircraftDialog({
    super.key,
    this.initialModel,
    this.initialEndorsement,
  });

  @override
  ConsumerState<EndorseAircraftDialog> createState() =>
      _EndorseAircraftDialogState();
}

class _EndorseAircraftDialogState extends ConsumerState<EndorseAircraftDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  late TextEditingController _instructorNameController;
  late TextEditingController _instructorLicenceController;
  late TextEditingController _notesController;

  late AircraftClass _aircraftClass;
  late DateTime _pilotDate;
  DateTime? _instructorDate;
  String? _sourceDocumentId;
  bool _recordEndorsement = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.initialModel;
    final e = widget.initialEndorsement;

    _idController = TextEditingController(text: m?.id ?? '');
    _manufacturerController = TextEditingController(
      text: m?.manufacturer ?? '',
    );
    _modelController = TextEditingController(text: m?.model ?? '');
    _instructorNameController = TextEditingController(
      text: e?.instructorName ?? '',
    );
    _instructorLicenceController = TextEditingController(
      text: e?.instructorLicence ?? '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');

    _aircraftClass = m?.aircraftClass ?? AircraftClass.singleEngine;
    _pilotDate = e?.pilotDate ?? DateTime.now();
    _instructorDate = e?.instructorDate;
    _sourceDocumentId = e?.sourceDocumentId;
    _recordEndorsement = e != null || m == null;
  }

  @override
  void dispose() {
    _idController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _instructorNameController.dispose();
    _instructorLicenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPilotDate}) async {
    final initial = isPilotDate
        ? _pilotDate
        : (_instructorDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1960),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPilotDate) {
          _pilotDate = picked;
        } else {
          _instructorDate = picked;
        }
      });
    }
  }

  Future<void> _selectVaultDocument() async {
    final repo = ref.read(endorsementsRepositoryProvider);
    final docs = await repo.getEndorsements(includeSuperseded: true);

    if (!mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Vault Scan',
                      style: Theme.of(ctx).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.document_scanner, color: Colors.blue),
                title: const Text('Scan / Upload New Document'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ScanEndorsementDialog(),
                  );
                  if (result == true) {
                    final updatedDocs = await repo.getEndorsements(
                      includeSuperseded: true,
                    );
                    if (updatedDocs.isNotEmpty && mounted) {
                      setState(() {
                        _sourceDocumentId = updatedDocs.first.id;
                      });
                    }
                  }
                },
              ),
              if (_sourceDocumentId != null)
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.red),
                  title: const Text('Remove Attached Document'),
                  onTap: () => Navigator.of(ctx).pop('CLEAR'),
                ),
              const Divider(height: 1),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No documents in Endorsement Vault yet.'),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final doc = docs[idx];
                      final isSelected = doc.id == _sourceDocumentId;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.verified_outlined, size: 20),
                        title: Text(
                          '${doc.category.label} • ${doc.pageCount} ${doc.pageCount == 1 ? 'page' : 'pages'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: ${TimeUtils.formatDate(doc.endorsementDate)} • SHA: ${doc.sha256.substring(0, 8)}...',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(doc.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _sourceDocumentId = picked == 'CLEAR' ? null : picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? removalReason;
    if (!_recordEndorsement && widget.initialEndorsement != null) {
      removalReason = await showDialog<String>(context: context,
        builder: (_) => const _EndorsementRemovalDialog());
      if (!mounted || removalReason == null) return;
    }
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(aircraftRepositoryProvider);
      final modelId = _idController.text.trim().toUpperCase();

      final model = AircraftModel(
        id: modelId,
        manufacturer: _manufacturerController.text.trim(),
        model: _modelController.text.trim(),
        aircraftClass: _aircraftClass,
        category: AircraftCategory.aeroplane,
      );

      await repo.saveModel(model);

      if (_recordEndorsement) {
        final existingEndorsement = widget.initialEndorsement;
        final endorsement = ModelEndorsement(
          id:
              existingEndorsement?.id ??
              'me_${DateTime.now().millisecondsSinceEpoch}',
          aircraftModelId: modelId,
          pilotDate: _pilotDate,
          instructorDate: _instructorDate,
          instructorName: _instructorNameController.text.trim().isEmpty
              ? null
              : _instructorNameController.text.trim(),
          instructorLicence: _instructorLicenceController.text.trim().isEmpty
              ? null
              : _instructorLicenceController.text.trim(),
          sourceDocumentId: _sourceDocumentId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: existingEndorsement?.createdAt ?? DateTime.now(),
        );
        await repo.saveEndorsement(endorsement);
      } else if (widget.initialEndorsement != null) {
        await repo.deleteEndorsement(
          widget.initialEndorsement!.id,
          reason: removalReason!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !_recordEndorsement && widget.initialEndorsement != null
                  ? 'Endorsement removed; aircraft and scans kept'
                  : 'Aircraft ${model.displayName} saved successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving aircraft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialModel != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.airplanemode_active,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Edit Aircraft & Endorsement'
                            : 'Register Aircraft Model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Divider(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Model Code & Class
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _idController,
                                decoration: const InputDecoration(
                                  labelText: 'ICAO Code *',
                                  hintText: 'e.g. C172',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SegmentedButton<AircraftClass>(
                                    showSelectedIcon: false,
                                    segments: const [
                                      ButtonSegment(
                                        value: AircraftClass.singleEngine,
                                        label: Text(
                                          'SE',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: AircraftClass.multiEngine,
                                        label: Text(
                                          'ME',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                    selected: {_aircraftClass},
                                    onSelectionChanged: (s) => setState(
                                      () => _aircraftClass = s.first,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Manufacturer
                        TextFormField(
                          controller: _manufacturerController,
                          decoration: const InputDecoration(
                            labelText: 'Manufacturer *',
                            hintText: 'e.g. Cessna, Piper, Beechcraft',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Model Name
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model Name *',
                            hintText: 'e.g. 172 Skyhawk, PA-28, 76 Duchess',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Endorsement Section Toggle
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Record Differences / Type Endorsement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Log checkout date and authorized instructor sign-off.',
                            style: TextStyle(fontSize: 11),
                          ),
                          value: _recordEndorsement,
                          dense: true,
                          onChanged: (v) =>
                              setState(() => _recordEndorsement = v),
                        ),

                        if (_recordEndorsement) ...[
                          const SizedBox(height: 8),
                          // Pilot Endorsement Date
                          InkWell(
                            onTap: () => _pickDate(isPilotDate: true),
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Pilot Endorsement Date *',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                              ),
                              child: Text(TimeUtils.formatDate(_pilotDate)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Instructor Sign-Off Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Instructor Sign-Off (Optional)',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                InkWell(
                                  onTap: () => _pickDate(isPilotDate: false),
                                  borderRadius: BorderRadius.circular(4),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Instructor Test Date',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: const Icon(
                                        Icons.event_available,
                                        size: 18,
                                      ),
                                      suffixIcon: _instructorDate != null
                                          ? IconButton(
                                              tooltip: 'Clear date',
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 16,
                                              ),
                                              onPressed: () => setState(
                                                () => _instructorDate = null,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      _instructorDate != null
                                          ? TimeUtils.formatDate(
                                              _instructorDate!,
                                            )
                                          : 'Not Specified',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                TextFormField(
                                  controller: _instructorNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Instructor Name',
                                    hintText: 'e.g. CAPT J. MILLER',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      size: 18,
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                                const SizedBox(height: 10),

                                TextFormField(
                                  controller: _instructorLicenceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Instructor Licence Number',
                                    hintText: 'e.g. ZA-642918',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Endorsement Vault Document Link
                          InkWell(
                            onTap: _selectVaultDocument,
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Linked Vault Document Scan',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: Icon(Icons.attachment, size: 18),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(
                                _sourceDocumentId != null
                                    ? 'Attached Document (ID: ${_sourceDocumentId!.length > 12 ? _sourceDocumentId!.substring(0, 12) : _sourceDocumentId}..)'
                                    : 'None (Tap to attach scan)',
                                style: TextStyle(
                                  color: _sourceDocumentId != null
                                      ? theme.colorScheme.primary
                                      : null,
                                  fontWeight: _sourceDocumentId != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Endorsement Notes',
                              hintText: 'e.g. Differences training completed on G1000 glass cockpit',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save Aircraft'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndorsementRemovalDialog extends StatefulWidget {
  const _EndorsementRemovalDialog();
  @override
  State<_EndorsementRemovalDialog> createState() => _EndorsementRemovalDialogState();
}
class _EndorsementRemovalDialogState extends State<_EndorsementRemovalDialog> {
  final _controller = TextEditingController();
  String? _error;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Remove recorded endorsement?'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('The aircraft, flights and original Vault scan will be kept. A correction record will preserve the removed endorsement.'),
      TextField(controller: _controller, decoration: InputDecoration(labelText: 'Reason for correction', errorText: _error)),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () {
        final reason = _controller.text.trim();
        if (reason.isEmpty) { setState(() => _error = 'Enter a reason'); return; }
        Navigator.pop(context, reason);
      }, child: const Text('Remove endorsement'))],
  );
}
