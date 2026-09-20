import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../domain/endorsement_category.dart';
import '../../domain/endorsement_document.dart';
import '../providers/endorsements_providers.dart';
import '../utils/sample_endorsement_generator.dart';


class ScanEndorsementDialog extends ConsumerStatefulWidget {
  final EndorsementDocument? supersedingDocument;

  const ScanEndorsementDialog({
    super.key,
    this.supersedingDocument,
  });

  @override
  ConsumerState<ScanEndorsementDialog> createState() => _ScanEndorsementDialogState();
}

class _ScanEndorsementDialogState extends ConsumerState<ScanEndorsementDialog> {
  final _formKey = GlobalKey<FormState>();

  late EndorsementCategory _selectedCategory;
  late DateTime _endorsementDate;
  final TextEditingController _pageNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Uint8List? _capturedBytes;
  String _fileExtension = 'png';
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.supersedingDocument?.category ?? EndorsementCategory.tw;
    _endorsementDate = widget.supersedingDocument?.endorsementDate ?? DateTime.now();
    if (widget.supersedingDocument?.pageNumber != null) {
      _pageNumberController.text = widget.supersedingDocument!.pageNumber.toString();
    }
  }

  @override
  void dispose() {
    _pageNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    setState(() => _isScanning = true);
    try {
      final scanner = ref.read(documentScannerPortProvider);
      final paths = await scanner.getScannedImagePaths();
      if (paths.isNotEmpty && mounted) {
        final path = paths.first;
        if (!kIsWeb) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          setState(() {
            _capturedBytes = bytes;
            _fileExtension = path.split('.').last;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner unavailable on this device: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _generateSampleStamp() async {
    setState(() => _isScanning = true);
    try {
      final bytes = await SampleEndorsementGenerator.generateStampImage(
        title: _selectedCategory.label,
        regulator: 'SACAA / ICAO',
        details: 'Type endorsement and competency test completed with authorized instructor.',
        date: _endorsementDate,
      );
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
          _fileExtension = 'png';
        });
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endorsementDate,
      firstDate: DateTime(1960),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endorsementDate = picked);
    }
  }

  Future<void> _selectCategory() async {
    final picked = await showModalBottomSheet<EndorsementCategory>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                      'Select Endorsement Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: EndorsementCategory.values.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return ListTile(
                      dense: true,
                      title: Text(
                        cat.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(cat),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedCategory = picked);
    }
  }

  Future<void> _save() async {
    if (_capturedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or generate a document scan first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(endorsementsRepositoryProvider);
      final pageNum = int.tryParse(_pageNumberController.text.trim());

      await repo.saveEndorsement(
        category: _selectedCategory,
        endorsementDate: _endorsementDate,
        pageNumber: pageNum,
        imageBytes: _capturedBytes!,
        fileExtension: _fileExtension,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        supersedesId: widget.supersedingDocument?.id,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.supersedingDocument != null
                  ? 'Replacement endorsement saved successfully'
                  : 'Endorsement scan saved to vault',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving endorsement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = TimeUtils.formatDate(_endorsementDate);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      widget.supersedingDocument != null
                          ? Icons.published_with_changes
                          : Icons.document_scanner,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.supersedingDocument != null
                            ? 'Supersede Endorsement'
                            : 'Scan Logbook Endorsement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

              // Scrollable form body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (widget.supersedingDocument != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This new scan will supersede document #${widget.supersedingDocument!.id} and become the active certified record.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Document Capture Preview Area
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _capturedBytes != null ? Colors.green : colorScheme.outlineVariant,
                          width: _capturedBytes != null ? 2 : 1,
                        ),
                      ),
                      child: _capturedBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    _capturedBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Scan Ready',
                                          style: TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 40, color: colorScheme.outline),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No document scan attached yet',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // Ingest action buttons
                    Row(
                      children: [
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.android ||
                                defaultTargetPlatform == TargetPlatform.iOS))
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isScanning ? null : _scanWithCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera Scanner'),
                            ),
                          ),
                        if (!kIsWeb &&
                            (defaultTargetPlatform == TargetPlatform.android ||
                                defaultTargetPlatform == TargetPlatform.iOS))
                          const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isScanning ? null : _generateSampleStamp,
                            icon: const Icon(Icons.verified),
                            label: const Text('Test Stamp / Cert'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Endorsement Category
                    InkWell(
                      onTap: _selectCategory,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Endorsement Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedCategory.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date and Page Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of Endorsement *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(formattedDate),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _pageNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Page No.',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.menu_book),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / CFI Name / License No.',
                        hintText: 'e.g. Sign-off by Capt. J. Miller CFI #642918',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Bottom action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save to Vault'),
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
}
