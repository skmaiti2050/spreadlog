import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/duration_picker_dialog.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../../aircraft/presentation/providers/aircraft_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/flight.dart';
import '../../domain/flight_draft.dart';
import '../../domain/registration_suggestion.dart';
import '../../data/entry_preferences.dart';
import '../../data/flight_drafts_repository.dart';
import '../../domain/hobbs_reading.dart';
import '../../domain/flight_time.dart';
import '../../domain/instrument_time.dart';
import '../../domain/landings.dart';
import '../providers/flights_providers.dart';

/// Progressive multi-step card modal for logging flights.
/// Adapts seamlessly from ultra-narrow 320px mobile screens to spacious desktop tablets.
class LogFlightDialog extends ConsumerStatefulWidget {
  final Flight? initialFlight;
  final bool isFullScreen;
  final String? initialRevision;

  const LogFlightDialog({
    super.key,
    this.initialFlight,
    this.initialRevision,
    this.isFullScreen = false,
  });

  static Future<Flight?> show(
    BuildContext context, {
    Flight? initialFlight,
  }) async {
    String? revision;
    if (initialFlight != null) {
      final container = ProviderScope.containerOf(context, listen: false);
      final drafts = container.read(flightDraftsRepositoryProvider);
      final id = initialFlight.id;
      final source = await drafts.db.transaction(() async {
        final flights = await container
            .read(flightsRepositoryProvider)
            .getAllFlights();
        final matching = flights.where((flight) => flight.id == id);
        return (
          flight: matching.firstOrNull,
          revision: await drafts.revision(id),
        );
      });
      if (!context.mounted || source.flight == null) return null;
      initialFlight = source.flight;
      revision = source.revision;
    }
    if (!context.mounted) return null;
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Navigator.of(context).push<Flight>(
        MaterialPageRoute<Flight>(
          fullscreenDialog: true,
          builder: (context) => LogFlightDialog(
            initialFlight: initialFlight,
            initialRevision: revision,
            isFullScreen: true,
          ),
        ),
      );
    }
    return showDialog<Flight>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
          child: LogFlightDialog(
            initialFlight: initialFlight,
            initialRevision: revision,
            isFullScreen: false,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LogFlightDialog> createState() => _LogFlightDialogState();
}

class _LogFlightDialogState extends ConsumerState<LogFlightDialog>
    with WidgetsBindingObserver {
  late final SqliteFlightDraftRepository _drafts;
  Timer? _draftTimer;
  Future<void> _pendingWrites = Future.value();
  bool _draftReady = false;
  bool _aircraftSuggested = false;
  bool _dirty = false;
  bool _saving = false;
  bool _finalized = false;
  String? _baseRevision;
  String _draftStatus = '';

  Map<String, TextEditingController> get _inputControllers => {
    'type': _typeController,
    'registration': _regController,
    'pic': _picController,
    'duration': _durationController,
    'remarks': _remarksController,
    'decimal': _decimalController,
    'hobbsStart': _hobbsStartController,
    'hobbsEnd': _hobbsEndController,
    'adjustment': _adjustmentController,
    'offBlocks': _offBlocksController,
    'onBlocks': _onBlocksController,
    'instrumentActual': _instActualController,
    'instrumentFstd': _instFstdController,
    'navaids': _navaidsController,
    'place': _placeController,
  };

  FlightDraft _snapshot() {
    final duration = TimeUtils.tryParseHhMmToMinutes(_durationController.text);
    final start = TimeUtils.tryParseHourTenths(_hobbsStartController.text);
    final end = TimeUtils.tryParseHourTenths(_hobbsEndController.text);
    return FlightDraft(
      flightId: widget.initialFlight?.id,
      baseRevision: _baseRevision,
      updatedAt: DateTime.now(),
      fields: {
        for (final entry in _inputControllers.entries)
          entry.key: entry.value.text,
        'aircraftSuggested': '$_aircraftSuggested',
        'date': _date.toIso8601String(),
        'mode': _durationSource,
        'category': _aircraftCategory.name,
        'class': _aircraftClass.name,
        'role': _role.name,
        'period': _period.name,
        'fstd': '$_isFstd',
        'solo': '$_soloCrossCountry',
        'dayLandings': '$_dayLandings',
        'nightLandings': '$_nightLandings',
        'blockTimes': '$_showBlockTimes',
        'startEdited': '$_startEdited',
        'step': '$_currentStep',
      },
      validatedValues: {
        'durationMinutes': ?duration,
        'instrumentActualMinutes': ?TimeUtils.tryParseHhMmToMinutes(
          _instActualController.text,
        ),
        'instrumentFstdMinutes': ?TimeUtils.tryParseHhMmToMinutes(
          _instFstdController.text,
        ),
        'dayLandings': _dayLandings,
        'nightLandings': _nightLandings,
        'hobbsStartTenths': ?start,
        'hobbsEndTenths': ?end,
      },
    );
  }

  void _restoreDraft(FlightDraft draft) {
    final fields = draft.fields;
    // Registration listeners must not erase recovered meter readings.
    _regController.removeListener(_registrationForHobbsChanged);
    for (final entry in _inputControllers.entries) {
      entry.value.text = fields[entry.key] ?? '';
    }
    _hobbsRegistration = HobbsReading.normalizeRegistration(
      _regController.text,
    );
    _regController.addListener(_registrationForHobbsChanged);
    _date = DateTime.parse(fields['date']!);
    _durationSource = fields['mode']!;
    _aircraftCategory = AircraftCategory.values.byName(fields['category']!);
    _aircraftClass = AircraftClass.values.byName(fields['class']!);
    _role = PilotRole.values.byName(fields['role']!);
    _period = TimePeriod.values.byName(fields['period']!);
    _isFstd = fields['fstd'] == 'true';
    _soloCrossCountry = fields['solo'] == 'true';
    _dayLandings = int.parse(fields['dayLandings']!);
    _nightLandings = int.parse(fields['nightLandings']!);
    _showBlockTimes = fields['blockTimes'] == 'true';
    _startEdited = true;
    _aircraftSuggested = fields['aircraftSuggested'] == 'true';
    _currentStep = int.parse(fields['step']!).clamp(0, 2);
    _baseRevision = draft.baseRevision;
    _dirty = true;
  }

  Future<void> _loadDraft() async {
    try {
      if (!_isEditing) {
        _durationSource = await const EntryPreferences().loadDurationMode();
      }
      _baseRevision =
          widget.initialRevision ??
          (widget.initialFlight == null
              ? null
              : await _drafts.revision(widget.initialFlight!.id));
      if (_isEditing && _baseRevision == null) {
        throw const FlightDraftConflict();
      }
      final draft = await _drafts.get(widget.initialFlight?.id);
      if (!mounted) return;
      if (draft != null) {
        final resume = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Resume unfinished entry?'),
            content: const Text(
              'Your saved draft has not been added to your logbook.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Discard'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Resume'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (resume == true) {
          _restoreDraft(draft);
          _draftStatus = 'Draft saved on this device';
        } else if (resume == false) {
          final discard = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Discard this draft?'),
              content: const Text(
                'The unfinished input will be removed. Logged flights stay unchanged.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Keep draft'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard draft'),
                ),
              ],
            ),
          );
          if (discard != true) {
            if (mounted) {
              Navigator.pop(context);
            }
            return;
          }
          await _drafts.discard(widget.initialFlight?.id);
        } else {
          if (mounted) {
            Navigator.pop(context);
          }
          return;
        }
      }
      if (!mounted) return;
      super.setState(() => _draftReady = true);
      if (_currentStep != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pageController.jumpToPage(_currentStep);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _draftStatus = 'Could not load your draft. Close and try again.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _draftReady) {
      _draftTimer?.cancel();
      _persistDraft();
    }
  }

  void _draftChanged() {
    if (!_draftReady || _finalized || _saving) return;
    _dirty = true;
    if (mounted && _draftStatus != 'Saving draft…') {
      super.setState(() => _draftStatus = 'Saving draft…');
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 350), _persistDraft);
  }

  void _persistDraft() {
    if (!_dirty || _finalized) return;
    final snapshot = _snapshot();
    _pendingWrites = _pendingWrites.then((_) => _drafts.save(snapshot));
    _pendingWrites = _pendingWrites
        .then((_) {
          if (mounted) {
            super.setState(() => _draftStatus = 'Draft saved on this device');
          }
        })
        .catchError((Object error) {
          if (mounted) {
            super.setState(
              () => _draftStatus = 'Draft could not be saved. Keep this entry open and try again.',
            );
          }
        });
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _draftChanged();
  }

  final _pageController = PageController();
  int _currentStep = 0;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  bool get _isEditing => widget.initialFlight != null;

  DateTime _date = DateTime.now();
  late final TextEditingController _typeController;
  late final TextEditingController _regController;
  late final TextEditingController _picController;
  late final TextEditingController _durationController;
  late final TextEditingController _remarksController;

  String _durationSource = 'hhMm';
  final _decimalController = TextEditingController();
  final _hobbsStartController = TextEditingController();
  final _hobbsEndController = TextEditingController();
  final _adjustmentController = TextEditingController();
  bool _startEdited = false;
  String _hobbsRegistration = '';

  void _updateHobbsDuration() {
    if (_durationSource != 'hobbs') return;
    final minutes = _hobbsMinutes;
    _durationController.text = minutes == null
        ? ''
        : TimeUtils.formatMinutesToHhMm(minutes);
  }

  void _registrationForHobbsChanged() {
    final registration = HobbsReading.normalizeRegistration(
      _regController.text,
    );
    if (registration == _hobbsRegistration) return;
    _hobbsRegistration = registration;
    _startEdited = false;
    _hobbsEndController.clear();
    _prefillHobbs();
    _updateHobbsDuration();
  }

  void _prefillHobbs() {
    if (_startEdited) return;
    final value = HobbsReading.previousEnd(
      ref.read(flightsStreamProvider).value ?? const <Flight>[],
      registration: _regController.text,
      date: _date,
      excludingId: widget.initialFlight?.id,
      beforeCreatedAt: widget.initialFlight?.createdAt,
    );
    final previousText = _hobbsStartController.text;
    _hobbsStartController.text = value == null
        ? ''
        : TimeUtils.formatHourTenths(value);
    if (_hobbsStartController.text != previousText) _updateHobbsDuration();
  }

  int? get _hobbsMinutes {
    final start = TimeUtils.tryParseHourTenths(_hobbsStartController.text);
    final end = TimeUtils.tryParseHourTenths(_hobbsEndController.text);
    return start == null || end == null || end <= start
        ? null
        : (end - start) * 6;
  }

  // Block time calculator
  bool _showBlockTimes = false;
  final _offBlocksController = TextEditingController();
  final _onBlocksController = TextEditingController();

  AircraftCategory _aircraftCategory = AircraftCategory.aeroplane;
  AircraftClass _aircraftClass = AircraftClass.singleEngine;
  PilotRole _role = PilotRole.pic;
  TimePeriod _period = TimePeriod.day;
  bool _isFstd = false;
  bool _soloCrossCountry = false;

  int _dayLandings = 1;
  int _nightLandings = 0;

  late final TextEditingController _instActualController;
  late final TextEditingController _instFstdController;
  late final TextEditingController _navaidsController;
  late final TextEditingController _placeController;

  static const List<Map<String, String>> _popularAirfields = [
    {'code': 'FALA', 'name': 'Lanseria'},
    {'code': 'FAGM', 'name': 'Rand'},
    {'code': 'FAWB', 'name': 'Wonderboom'},
    {'code': 'FAKR', 'name': 'Krugersdorp'},
    {'code': 'FAGC', 'name': 'Grand Central'},
    {'code': 'FACT', 'name': 'Cape Town'},
    {'code': 'FASH', 'name': 'Stellenbosch'},
    {'code': 'FAPM', 'name': 'Pietermaritzburg'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = ref.read(pilotProfileProvider);
    final init = widget.initialFlight;

    if (init != null) {
      _date = init.date;
      _aircraftCategory = init.aircraftCategory;
      _durationSource = init.durationSource;
      _startEdited = init.hobbsStartTenths != null;
      _hobbsStartController.text = init.hobbsStartTenths == null
          ? ''
          : TimeUtils.formatHourTenths(init.hobbsStartTenths!);
      _hobbsEndController.text = init.hobbsEndTenths == null
          ? ''
          : TimeUtils.formatHourTenths(init.hobbsEndTenths!);
      _adjustmentController.text = init.durationAdjustmentReason;
      _typeController = TextEditingController(
        text: init.aircraftModelId ?? 'C172',
      );
      _regController = TextEditingController(text: init.registration);
      _picController = TextEditingController(text: init.picName);
      _remarksController = TextEditingController(text: init.remarks);
      _soloCrossCountry = init.soloCrossCountry;
      _isFstd = init.isFstd;
      _dayLandings = init.landings.dayCount;
      _nightLandings = init.landings.nightCount;

      if (_isFstd) {
        _durationController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(init.fstdActualMinutes),
        );
      } else if (init.flightTimes.isNotEmpty) {
        final ft = init.flightTimes.first;
        _aircraftClass = ft.aircraftClass;
        _period = ft.period;
        _role = ft.role;
        _durationController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(ft.durationMinutes),
        );
      } else {
        _durationController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(init.totalDurationMinutes),
        );
      }

      if (init.instrumentTime != null) {
        _instActualController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(
            init.instrumentTime!.actualMinutes,
          ),
        );
        _instFstdController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(init.instrumentTime!.fstdMinutes),
        );
        _navaidsController = TextEditingController(
          text: init.instrumentTime!.navaids ?? '',
        );
        _placeController = TextEditingController(
          text: init.instrumentTime!.place ?? '',
        );
      } else {
        _instActualController = TextEditingController(text: '00:00');
        _instFstdController = TextEditingController(text: '00:00');
        _navaidsController = TextEditingController();
        _placeController = TextEditingController();
      }
    } else {
      // Pilots usually fly the same aircraft again, so start from the most
      // recent flight; never invent a type, duration or remarks.
      final flights = ref.read(flightsStreamProvider).value ?? const <Flight>[];
      final latest = flights.isEmpty
          ? null
          : flights.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      if (latest != null) {
        _aircraftCategory = latest.aircraftCategory;
        _isFstd = latest.isFstd;
        if (latest.flightTimes.isNotEmpty) {
          _aircraftClass = latest.flightTimes.first.aircraftClass;
        }
      }
      _typeController = TextEditingController(
        text: latest?.aircraftModelId ?? '',
      );
      _regController = TextEditingController(
        text: latest?.registration ?? 'ZS-',
      );
      _picController = TextEditingController(
        text: profile.defaultPicName.isNotEmpty
            ? profile.defaultPicName
            : 'SELF',
      );
      _durationController = TextEditingController();
      _remarksController = TextEditingController();
      _instActualController = TextEditingController(text: '00:00');
      _instFstdController = TextEditingController(text: '00:00');
      _navaidsController = TextEditingController();
      _placeController = TextEditingController();
    }
    if (_durationSource == 'decimal') {
      _decimalController.text = TimeUtils.formatMinutesToDecimal(
        TimeUtils.tryParseHhMmToMinutes(_durationController.text) ?? 0,
      );
    }
    _hobbsRegistration = HobbsReading.normalizeRegistration(
      _regController.text,
    );
    _regController.addListener(_registrationForHobbsChanged);
    _prefillHobbs();
    _drafts = ref.read(flightDraftsRepositoryProvider);
    for (final controller in _inputControllers.values) {
      controller.addListener(_draftChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_loadDraft()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _persistDraft();
    for (final controller in _inputControllers.values) {
      controller.removeListener(_draftChanged);
    }
    _decimalController.dispose();
    _hobbsStartController.dispose();
    _hobbsEndController.dispose();
    _adjustmentController.dispose();
    _pageController.dispose();
    _typeController.dispose();
    _regController.dispose();
    _picController.dispose();
    _durationController.dispose();
    _remarksController.dispose();
    _offBlocksController.dispose();
    _onBlocksController.dispose();
    _instActualController.dispose();
    _instFstdController.dispose();
    _navaidsController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(1980),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _prefillHobbs();
      });
    }
  }

  RegistrationSuggestion? get _registrationSuggestion =>
      RegistrationSuggestion.find(
        registration: _regController.text,
        flights: ref.watch(flightsStreamProvider).value ?? const [],
        fleet: ref.watch(allAircraftModelsProvider).value ?? const [],
        excludingId: widget.initialFlight?.id,
      );

  void _applyAircraftSuggestion(RegistrationSuggestion suggestion) {
    setState(() {
      _typeController.text = suggestion.modelId;
      _aircraftCategory = suggestion.category;
      _aircraftClass = suggestion.aircraftClass;
      _isFstd = suggestion.category == AircraftCategory.fstd;
      _aircraftSuggested = true;
    });
  }

  Future<void> _rememberMode(String mode) async {
    try {
      await const EntryPreferences().saveDurationMode(mode);
    } catch (_) {
      if (mounted) {
        super.setState(
          () => _draftStatus =
              'Entry mode could not be remembered. Your entry is still open.',
        );
      }
    }
  }

  void _onRegChanged(String value) {
    setState(() => _aircraftSuggested = false);
    String upper = value.toUpperCase().replaceAll(' ', '');
    if (upper.length >= 3 && !upper.contains('-')) {
      if (upper.startsWith('ZS') ||
          upper.startsWith('ZU') ||
          upper.startsWith('ZT')) {
        upper = '${upper.substring(0, 2)}-${upper.substring(2)}';
        _regController.value = TextEditingValue(
          text: upper,
          selection: TextSelection.collapsed(offset: upper.length),
        );
        _prefillHobbs();
        return;
      }
    }
    if (upper != value) {
      _regController.value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
  }

  void _onTypeSelected(String type, [AircraftModel? model]) {
    setState(() {
      _typeController.text = type;
      if (model != null) {
        _isFstd = model.category == AircraftCategory.fstd || type == 'FNPT II';
        _aircraftClass = model.aircraftClass;
        _aircraftCategory = model.category;
      } else {
        if (type == 'FNPT II') {
          _isFstd = true;
        } else {
          _isFstd = false;
          if (['BE76', 'DA42', 'PA34'].contains(type)) {
            _aircraftClass = AircraftClass.multiEngine;
          } else {
            _aircraftClass = AircraftClass.singleEngine;
          }
        }
      }
    });
  }

  void _appendAirfield(String code) {
    final current = _remarksController.text.trim();
    if (current.isEmpty) {
      _remarksController.text = code;
    } else if (!current.contains(code)) {
      _remarksController.text = '$current - $code';
    }
  }

  void _applyBlockTimes() {
    if (_durationSource == 'decimal') _durationSource = 'hhMm';
    final offText = _offBlocksController.text.trim();
    final onText = _onBlocksController.text.trim();
    final offMins = TimeUtils.tryParseHhMmToMinutes(offText);
    final onMins = TimeUtils.tryParseHhMmToMinutes(onText);

    if (offMins != null && onMins != null) {
      int diff = onMins - offMins;
      if (diff < 0) diff += 24 * 60; // Rolled over midnight
      if (diff > 0) {
        setState(() {
          _durationController.text = TimeUtils.formatMinutesToHhMm(diff);
          _showBlockTimes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Calculated flight time: ${TimeUtils.formatMinutesToHhMm(diff)} ($diff mins)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickFlightDuration() async {
    if (_durationSource == 'decimal') setState(() => _durationSource = 'hhMm');
    final currentMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 90;
    final picked = await DurationPickerDialog.show(
      context,
      initialMinutes: currentMins,
      title: _isFstd ? 'FSTD Flight Duration' : 'Total Flight Duration',
    );
    if (picked != null) {
      setState(() {
        _durationController.text = TimeUtils.formatMinutesToHhMm(picked);
      });
    }
  }

  void _quickSetDuration(int mins) {
    setState(() {
      if (_durationSource == 'decimal') _durationSource = 'hhMm';
      _durationController.text = TimeUtils.formatMinutesToHhMm(mins);
    });
  }

  void _quickAddDurationMinutes(int addMins) {
    if (_durationSource == 'decimal') _durationSource = 'hhMm';
    final current =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    final updated = (current + addMins).clamp(0, 99 * 60);
    setState(() {
      _durationController.text = TimeUtils.formatMinutesToHhMm(updated);
    });
  }

  Future<void> _pickBlockTime(
    TextEditingController controller,
    String label,
  ) async {
    final initial = TimeUtils.tryParseHhMmToMinutes(controller.text.trim());
    final tod = initial != null
        ? TimeOfDay(hour: initial ~/ 60, minute: initial % 60)
        : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: tod,
      helpText: 'SELECT $label (24-HOUR)',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hStr = picked.hour.toString().padLeft(2, '0');
      final mStr = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hStr:$mStr';
      });
    }
  }

  Future<void> _pickInstrumentDuration(
    TextEditingController controller,
    String title,
  ) async {
    final currentMins =
        TimeUtils.tryParseHhMmToMinutes(controller.text.trim()) ?? 0;
    final picked = await DurationPickerDialog.show(
      context,
      initialMinutes: currentMins,
      title: title,
    );
    if (picked != null) {
      setState(() {
        controller.text = TimeUtils.formatMinutesToHhMm(picked);
      });
    }
  }

  void _applySyllabusTemplate(String templateName) {
    _durationSource = 'hhMm';
    _aircraftCategory = AircraftCategory.aeroplane;
    setState(() {
      switch (templateName) {
        case 'PPL Solo XC':
          _typeController.text = 'C172';
          _aircraftClass = AircraftClass.singleEngine;
          _isFstd = false;
          _role = PilotRole.pic;
          _period = TimePeriod.day;
          _durationController.text = '02:30';
          _dayLandings = 3;
          _nightLandings = 0;
          _soloCrossCountry = true;
          _remarksController.text = 'FALA - FAKR - FALA Solo XC (CAR 61.01.5)';
          _instActualController.text = '00:00';
          _instFstdController.text = '00:00';
          _navaidsController.text = 'VOR / Dead Reckoning';
          break;
        case 'Night Rating Dual':
          _typeController.text = 'C172';
          _aircraftClass = AircraftClass.singleEngine;
          _isFstd = false;
          _role = PilotRole.dual;
          _period = TimePeriod.night;
          _durationController.text = '01:30';
          _dayLandings = 0;
          _nightLandings = 5;
          _soloCrossCountry = false;
          _remarksController.text = 'FALA Night Circuits & Nav';
          break;
        case 'Multi-Engine Dual':
          _typeController.text = 'BE76';
          _aircraftClass = AircraftClass.multiEngine;
          _isFstd = false;
          _role = PilotRole.dual;
          _period = TimePeriod.day;
          _durationController.text = '01:30';
          _dayLandings = 2;
          _nightLandings = 0;
          _soloCrossCountry = false;
          _remarksController.text = 'FAGM Asymmetric Handling';
          break;
        case 'IF Sim (FNPT II)':
          _typeController.text = 'FNPT II';
          _isFstd = true;
          _durationController.text = '01:30';
          _dayLandings = 0;
          _nightLandings = 0;
          _soloCrossCountry = false;
          _instActualController.text = '00:00';
          _instFstdController.text = '01:30';
          _navaidsController.text = 'ILS RWY 03 / RNAV GNSS';
          _remarksController.text = 'Instrument Rating FSTD Session';
          break;
      }
      _aircraftCategory = _isFstd
          ? AircraftCategory.fstd
          : AircraftCategory.aeroplane;
    });
  }

  bool _validateStep(int step) {
    if (step == 0) {
      return _formKeyStep1.currentState?.validate() ?? true;
    } else if (step == 1) {
      if (!(_formKeyStep2.currentState?.validate() ?? true)) return false;
      if (_soloCrossCountry && _role == PilotRole.dual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Solo Cross-Country (CAR 61.01.5) cannot be logged as Dual',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      return true;
    } else if (step == 2) {
      if (!(_formKeyStep3.currentState?.validate() ?? true)) return false;
      final durationMins =
          TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
      final instActualMins =
          TimeUtils.tryParseHhMmToMinutes(_instActualController.text.trim()) ??
          0;
      if (!_isFstd && instActualMins > durationMins) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Actual instrument time cannot exceed total flight duration',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        unawaited(_onSave());
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onSave() async {
    if (_saving || !_draftReady) return;
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) return;

    final durationMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    final instActualMins =
        TimeUtils.tryParseHhMmToMinutes(_instActualController.text.trim()) ?? 0;
    final instFstdMins =
        TimeUtils.tryParseHhMmToMinutes(_instFstdController.text.trim()) ?? 0;

    final now = DateTime.now();
    final flightId =
        widget.initialFlight?.id ?? 'flight_${now.millisecondsSinceEpoch}';
    final createdAt = widget.initialFlight?.createdAt ?? now;

    final flight = Flight(
      id: flightId,
      date: _date,
      aircraftModelId: _typeController.text.trim().toUpperCase(),
      aircraftCategory: _aircraftCategory,
      registration: _regController.text.trim().toUpperCase(),
      picName: _picController.text.trim().toUpperCase(),
      remarks: _remarksController.text.trim(),
      soloCrossCountry: _soloCrossCountry,
      fstdActualMinutes: _isFstd ? durationMins : 0,
      durationSource: _durationSource,
      hobbsStartTenths: _durationSource == 'hobbs'
          ? TimeUtils.tryParseHourTenths(_hobbsStartController.text)
          : null,
      hobbsEndTenths: _durationSource == 'hobbs'
          ? TimeUtils.tryParseHourTenths(_hobbsEndController.text)
          : null,
      durationAdjustmentReason: _durationSource == 'hobbs'
          ? _adjustmentController.text.trim()
          : '',
      flightTimes: _isFstd
          ? const []
          : [
              FlightTime(
                aircraftClass: _aircraftClass,
                period: _period,
                role: _role,
                durationMinutes: durationMins,
              ),
            ],
      instrumentTime:
          (instActualMins > 0 ||
              instFstdMins > 0 ||
              _navaidsController.text.isNotEmpty ||
              _placeController.text.isNotEmpty)
          ? InstrumentTime(
              navaids: _navaidsController.text.trim(),
              place: _placeController.text.trim(),
              actualMinutes: instActualMins,
              fstdMinutes: instFstdMins,
            )
          : null,
      landings: Landings(dayCount: _dayLandings, nightCount: _nightLandings),
      createdAt: createdAt,
      updatedAt: now,
    );

    setState(() => _saving = true);
    _draftTimer?.cancel();
    _persistDraft();
    await _pendingWrites;
    try {
      await _drafts.finalize(flight, baseRevision: _baseRevision);
      _finalized = true;
      if (mounted) Navigator.of(context).pop(flight);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _draftStatus = error is FlightDraftConflict
            ? error.toString()
            : 'Flight could not be saved. Your draft is kept. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen(flightsStreamProvider, (previous, next) {
      if (next.hasValue && !_dirty) _prefillHobbs();
    });
    final title = _isEditing ? 'Edit Flight Entry' : 'Log Flight Entry';

    if (!_draftReady) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_draftStatus.isEmpty)
                  const Text('Checking saved drafts…')
                else
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_draftStatus),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final bodyContent = AbsorbPointer(
      absorbing: _saving,
      child: Column(
        children: [
          if (_draftStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _draftStatus,
                style: theme.textTheme.bodySmall,
                semanticsLabel: _draftStatus,
              ),
            ),
          // Step progress header
          _buildStepHeader(theme),
          const Divider(height: 1),

          // Multi-step pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                _buildStep1Aircraft(theme),
                _buildStep2TimesAndRole(theme),
                _buildStep3InstrumentAndReview(theme),
              ],
            ),
          ),

          // Bottom Navigation Bar
          _buildBottomBar(theme),
        ],
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(child: bodyContent),
      );
    }

    return Scaffold(backgroundColor: Colors.transparent, body: bodyContent);
  }

  Widget _buildStepHeader(ThemeData theme) {
    final steps = ['Aircraft', 'Time & Role', 'Review & Log'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_currentStep + 1} OF 3: ${steps[_currentStep].toUpperCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.primary,
                ),
              ),
              Row(
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _currentStep ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              minHeight: 3,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Aircraft(ThemeData theme) {
    final suggestion = _registrationSuggestion;
    final aircraftEntries = ref.watch(endorsedAircraftListProvider);
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HintBanner(
              hintKey: 'hint_step1_presets',
              message: 'Tap a Quick Syllabus Preset below to auto-fill aircraft model, class, and flight rules.',
            ),
            // SACAA Syllabus Presets
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Syllabus Quick Fill',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _templateChip('PPL Solo XC', Icons.flight_takeoff),
                      _templateChip(
                        'Night Rating Dual',
                        Icons.nightlight_round,
                      ),
                      _templateChip(
                        'Multi-Engine Dual',
                        Icons.airplanemode_active,
                      ),
                      _templateChip('IF Sim (FNPT II)', Icons.computer),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Flight Date Picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Flight Date',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _typeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Aircraft model / type',
                helperText:
                    'Type a one-off model code, or choose from Fleet below.',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an aircraft type'
                  : null,
              onChanged: (value) {
                final matches = aircraftEntries.where(
                  (entry) =>
                      entry.model.id.toUpperCase() ==
                      value.trim().toUpperCase(),
                );
                setState(() {});
                if (matches.isNotEmpty) {
                  _onTypeSelected(matches.first.model.id, matches.first.model);
                }
              },
            ),
            DropdownButtonFormField<AircraftCategory>(
              key: ValueKey(_aircraftCategory),
              initialValue: _aircraftCategory,
              decoration: const InputDecoration(labelText: 'Aircraft category'),
              items: [
                for (final category in AircraftCategory.values)
                  DropdownMenuItem(value: category, child: Text(category.name)),
              ],
              onChanged:
                  aircraftEntries.any(
                    (entry) =>
                        entry.model.id.toUpperCase() ==
                        _typeController.text.trim().toUpperCase(),
                  )
                  ? null
                  : (value) => setState(() {
                      _aircraftCategory = value ?? AircraftCategory.aeroplane;
                      _isFstd = _aircraftCategory == AircraftCategory.fstd;
                    }),
            ),
            TextButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Choose from Fleet'),
              onPressed: () async {
                final selected = await showModalBottomSheet<AircraftModel>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => _AircraftPicker(
                    models: aircraftEntries
                        .map((entry) => entry.model)
                        .toList(),
                  ),
                );
                if (selected != null && mounted) {
                  _onTypeSelected(selected.id, selected);
                }
              },
            ),
            const SizedBox(height: 16),

            // Registration
            TextFormField(
              controller: _regController,
              decoration: const InputDecoration(
                labelText: 'Aircraft Registration',
                hintText: 'e.g. ZS-EXT',
                prefixIcon: Icon(Icons.badge_outlined, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                final reg = v?.trim() ?? '';
                if (reg.isEmpty) return 'Required';
                // The nationality prefix alone (e.g. "ZS-") is not a mark.
                if (reg.endsWith('-')) return 'Complete the registration';
                return null;
              },
              onChanged: _onRegChanged,
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Suggested from this registration: ${suggestion.modelId}, ${suggestion.category.name}, ${suggestion.aircraftClass == AircraftClass.singleEngine ? "single engine" : "multi engine"}.',
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _applyAircraftSuggestion(suggestion),
                  child: const Text('Use aircraft details'),
                ),
              ),
            ],
            if (_aircraftSuggested)
              const Text(
                'Suggested aircraft details applied. Check and edit them before logging.',
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                ActionChip(
                  label: const Text(
                    'ZS- (Standard)',
                    style: TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _onRegChanged('ZS-'),
                ),
                ActionChip(
                  label: const Text(
                    'ZU- (NTCA)',
                    style: TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _onRegChanged('ZU-'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PIC Name
            TextFormField(
              controller: _picController,
              decoration: const InputDecoration(
                labelText: 'Pilot in Command (PIC)',
                hintText: 'e.g. SELF or CAPT J. DOE',
                prefixIcon: Icon(Icons.person_outline, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2TimesAndRole(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HintBanner(
              hintKey: 'hint_step2_block_calc',
              message: 'Tap duration to pick Hours:Minutes or tap the calculator (🖩) to compute from block times.',
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final mode in ['hhMm', 'decimal', 'hobbs'])
                  ChoiceChip(
                    label: Text(switch (mode) {
                      'decimal' => 'Decimal hours',
                      'hobbs' => 'Hobbs readings',
                      _ => 'Hours / minutes',
                    }),
                    selected: _durationSource == mode,
                    onSelected: (_) => setState(() {
                      _durationSource = mode;
                      unawaited(_rememberMode(mode));
                      if (mode == 'hobbs') {
                        _prefillHobbs();
                        _updateHobbsDuration();
                      }
                      if (mode == 'decimal') {
                        final minutes = TimeUtils.tryParseHhMmToMinutes(
                          _durationController.text,
                        );
                        _decimalController.text =
                            minutes != null && minutes % 6 == 0
                            ? TimeUtils.formatMinutesToDecimal(minutes)
                            : '';
                        if (_decimalController.text.isEmpty) {
                          _durationController.clear();
                        }
                      }
                    }),
                  ),
              ],
            ),
            if (_durationSource == 'decimal') ...[
              TextFormField(
                controller: _decimalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Decimal hours (e.g. 1.5)',
                  helperText: 'One decimal digit; 0.1 hour = 6 minutes.',
                ),
                onChanged: (text) {
                  final minutes = TimeUtils.tryParseDecimalToMinutes(text);
                  setState(
                    () => _durationController.text = minutes == null
                        ? ''
                        : TimeUtils.formatMinutesToHhMm(minutes),
                  );
                },
                validator: (value) {
                  if (value == null ||
                      TimeUtils.tryParseDecimalToMinutes(value) == null) {
                    return 'Enter whole hours or one decimal digit';
                  }
                  return null;
                },
              ),
            ],
            if (_durationSource == 'hobbs') ...[
              const Text(
                'Your school uses Hobbs elapsed time as logged duration. Check the suggested start against the aircraft meter. Overrides require a reason.',
              ),
              TextFormField(
                controller: _hobbsStartController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Hobbs start'),
                onChanged: (_) => setState(() {
                  _startEdited = true;
                  _updateHobbsDuration();
                }),
                validator: (value) =>
                    TimeUtils.tryParseHourTenths(value ?? '') == null
                    ? 'Enter a reading with at most one decimal digit'
                    : null,
              ),
              TextFormField(
                controller: _hobbsEndController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Hobbs end'),
                onChanged: (_) => setState(_updateHobbsDuration),
                validator: (_) => _hobbsMinutes == null
                    ? 'End reading must exceed start reading'
                    : null,
              ),
              if (_hobbsMinutes != null)
                Text(
                  'Meter elapsed: ${TimeUtils.formatMinutesToHhMm(_hobbsMinutes!)} (${TimeUtils.formatMinutesToDecimal(_hobbsMinutes!)} hours)',
                ),
              TextButton(
                onPressed: _hobbsMinutes == null
                    ? null
                    : () => setState(
                        () => _durationController.text =
                            TimeUtils.formatMinutesToHhMm(_hobbsMinutes!),
                      ),
                child: const Text('Use meter elapsed as logged duration'),
              ),
              TextFormField(
                controller: _adjustmentController,
                decoration: const InputDecoration(
                  labelText: 'Reason if logged duration differs',
                ),
                validator: (value) =>
                    _hobbsMinutes != null &&
                        TimeUtils.tryParseHhMmToMinutes(
                              _durationController.text,
                            ) !=
                            _hobbsMinutes &&
                        (value == null || value.trim().isEmpty)
                    ? 'Explain the adjusted logged duration'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            // Flight Duration
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    readOnly: true,
                    onTap: _pickFlightDuration,
                    decoration: InputDecoration(
                      labelText: _isFstd
                          ? 'FSTD Actual Time (Col 13)'
                          : 'Total Flight Duration',
                      hintText: 'Tap to select HH:MM',
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showBlockTimes
                              ? Icons.calculate
                              : Icons.calculate_outlined,
                          size: 20,
                        ),
                        tooltip: 'Calculate from Off/On Blocks',
                        onPressed: () =>
                            setState(() => _showBlockTimes = !_showBlockTimes),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final mins = TimeUtils.tryParseHhMmToMinutes(v);
                      if (mins == null || mins <= 0) return 'Enter > 0 mins';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Quick Duration Chips wrap so none hide past the screen edge
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _quickDurationChip('45m', 45),
                _quickDurationChip('1h 00m', 60),
                _quickDurationChip('1h 15m', 75),
                _quickDurationChip('1h 30m', 90),
                _quickDurationChip('2h 00m', 120),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14),
                  label: const Text('+15m', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => _quickAddDurationMinutes(15),
                ),
              ],
            ),

            // Block Time Calculator Dropdown
            if (_showBlockTimes) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block Time Calculator',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _offBlocksController,
                            readOnly: true,
                            onTap: () => _pickBlockTime(
                              _offBlocksController,
                              'Off Blocks',
                            ),
                            decoration: InputDecoration(
                              labelText: 'Off Blocks',
                              hintText: '09:00',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                tooltip: 'Pick off-blocks time',
                                icon: const Icon(Icons.access_time, size: 18),
                                onPressed: () => _pickBlockTime(
                                  _offBlocksController,
                                  'Off Blocks',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _onBlocksController,
                            readOnly: true,
                            onTap: () => _pickBlockTime(
                              _onBlocksController,
                              'On Blocks',
                            ),
                            decoration: InputDecoration(
                              labelText: 'On Blocks',
                              hintText: '10:30',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                tooltip: 'Pick on-blocks time',
                                icon: const Icon(Icons.access_time, size: 18),
                                onPressed: () => _pickBlockTime(
                                  _onBlocksController,
                                  'On Blocks',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _applyBlockTimes,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Aircraft Class & Period
            Row(
              children: [
                Expanded(
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
                      const SizedBox(height: 6),
                      SegmentedButton<AircraftClass>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: AircraftClass.singleEngine,
                            label: Text('SE', style: TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment(
                            value: AircraftClass.multiEngine,
                            label: Text('ME', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                        selected: {_aircraftClass},
                        onSelectionChanged: _isFstd
                            ? null
                            : (s) => setState(() => _aircraftClass = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<TimePeriod>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: TimePeriod.day,
                            label: Text('Day', style: TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment(
                            value: TimePeriod.night,
                            label: Text(
                              'Night',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        selected: {_period},
                        onSelectionChanged: _isFstd
                            ? null
                            : (s) => setState(() => _period = s.first),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Operating Role
            Text(
              'Pilot Operating Role',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<PilotRole>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: PilotRole.dual,
                  label: Text('DUAL', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: PilotRole.pic,
                  label: Text('PIC', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: PilotRole.picus,
                  label: Text('PICUS', style: TextStyle(fontSize: 10)),
                ),
                ButtonSegment(
                  value: PilotRole.copilot,
                  label: Text('COPILOT', style: TextStyle(fontSize: 10)),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (s) {
                setState(() {
                  _role = s.first;
                  if (_role != PilotRole.pic && _soloCrossCountry) {
                    _soloCrossCountry = false;
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // Landings
            Row(
              children: [
                Expanded(
                  child: _buildLandingStepper(
                    label: 'Day Landings (Col 30)',
                    value: _dayLandings,
                    onChanged: (v) => setState(() => _dayLandings = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLandingStepper(
                    label: 'Night Landings (Col 31)',
                    value: _nightLandings,
                    onChanged: (v) => setState(() => _nightLandings = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Solo Cross-Country (CAR 61.01.5)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Solo Cross-Country (CAR 61.01.5)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Must be flown as PIC. Required for licence renewal.',
                style: TextStyle(fontSize: 11),
              ),
              value: _soloCrossCountry,
              dense: true,
              onChanged: (v) {
                setState(() {
                  _soloCrossCountry = v;
                  if (v && _role != PilotRole.pic) {
                    _role = PilotRole.pic;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 50,
  }) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        isDense: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Decrease $label',
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            tooltip: 'Increase $label',
            icon: const Icon(Icons.add_circle_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  /// Echoes step 1 on the review step so the pilot checks the whole entry
  /// before logging it, with a shortcut back to change it.
  Widget _buildEntrySummary(ThemeData theme) {
    final type = _typeController.text.trim();
    final reg = _regController.text.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              [
                TimeUtils.formatLogbookDate(_date),
                if (type.isNotEmpty) type,
                if (reg.isNotEmpty) reg,
                'PIC: ${_picController.text.trim()}',
              ].join(' • '),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _currentStep = 0);
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3InstrumentAndReview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HintBanner(
              hintKey: 'hint_step3_logbook_audit',
              message: 'Tap airport chips to append to your route. The summary at the end shows which logbook columns this flight fills.',
            ),
            _buildEntrySummary(theme),
            const SizedBox(height: 12),
            // Instrument Flying Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Instrument Flying & Navaids (Optional)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _instActualController,
                          readOnly: true,
                          onTap: () => _pickInstrumentDuration(
                            _instActualController,
                            'Actual Instrument Time',
                          ),
                          decoration: InputDecoration(
                            labelText: 'Actual Inst (Col 8)',
                            hintText: '00:00',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.touch_app_outlined,
                                size: 18,
                              ),
                              tooltip: 'Select Hours & Minutes',
                              onPressed: () => _pickInstrumentDuration(
                                _instActualController,
                                'Actual Instrument Time',
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                            if (instMins == null) return 'HH:MM';
                            final durMins =
                                TimeUtils.tryParseHhMmToMinutes(
                                  _durationController.text.trim(),
                                ) ??
                                0;
                            if (!_isFstd && instMins > durMins) {
                              return 'Exceeds flight ($durMins m)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _instFstdController,
                          readOnly: true,
                          onTap: () => _pickInstrumentDuration(
                            _instFstdController,
                            'FSTD / Sim Instrument Time',
                          ),
                          decoration: InputDecoration(
                            labelText: 'FSTD Inst (Col 9)',
                            hintText: '00:00',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.touch_app_outlined,
                                size: 18,
                              ),
                              tooltip: 'Select Hours & Minutes',
                              onPressed: () => _pickInstrumentDuration(
                                _instFstdController,
                                'FSTD / Sim Instrument Time',
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                            if (instMins == null) return 'HH:MM';
                            final durMins =
                                TimeUtils.tryParseHhMmToMinutes(
                                  _durationController.text.trim(),
                                ) ??
                                0;
                            if (_isFstd && instMins > durMins) {
                              return 'Exceeds sim ($durMins m)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _navaidsController,
                          decoration: const InputDecoration(
                            labelText: 'Navaid used (Col 6)',
                            hintText: 'e.g. ILS RWY 03, VOR',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _placeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Place (Col 7)',
                            hintText: 'e.g. FALA',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Remarks & Route
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Route & Remarks (Column 5)',
                hintText: 'e.g. FALA - FAGM Local Training',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.local_airport_outlined,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Quick-Add Airfield:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _popularAirfields.map((af) {
                return ActionChip(
                  label: Text(
                    af['code']!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  tooltip: af['name'],
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => _appendAirfield(af['code']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Live 32-Column Allocation Badge
            _buildLiveColumnPill(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              onPressed: _previousStep,
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          FilledButton.icon(
            icon: Icon(
              _currentStep == 2 ? Icons.check : Icons.arrow_forward,
              size: 16,
            ),
            label: Text(
              _currentStep == 2
                  ? (_isEditing ? 'Save Changes' : 'Log Flight')
                  : 'Next',
            ),
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _templateChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: () => _applySyllabusTemplate(label),
    );
  }

  Widget _quickDurationChip(String label, int mins) {
    final currentMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    final isSelected = currentMins == mins;
    return ChoiceChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onSelected: (_) => _quickSetDuration(mins),
    );
  }

  Widget _buildLiveColumnPill(ThemeData theme) {
    final durMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    String colTarget;

    if (_isFstd) {
      colTarget = 'Col 13 (FSTD Actual)';
    } else if (_aircraftClass == AircraftClass.singleEngine) {
      if (_period == TimePeriod.day) {
        switch (_role) {
          case PilotRole.dual:
            colTarget = 'Col 14 (SE Day Dual)';
            break;
          case PilotRole.pic:
            colTarget = 'Col 15 (SE Day PIC)';
            break;
          case PilotRole.picus:
            colTarget = 'Col 16 (SE Day PICUS)';
            break;
          case PilotRole.copilot:
            colTarget = 'Col 17 (SE Day Copilot)';
            break;
        }
      } else {
        switch (_role) {
          case PilotRole.dual:
            colTarget = 'Col 18 (SE Night Dual)';
            break;
          case PilotRole.pic:
            colTarget = 'Col 19 (SE Night PIC)';
            break;
          case PilotRole.picus:
            colTarget = 'Col 20 (SE Night PICUS)';
            break;
          case PilotRole.copilot:
            colTarget = 'Col 21 (SE Night Copilot)';
            break;
        }
      }
    } else {
      if (_period == TimePeriod.day) {
        switch (_role) {
          case PilotRole.dual:
            colTarget = 'Col 22 (ME Day Dual)';
            break;
          case PilotRole.pic:
            colTarget = 'Col 23 (ME Day PIC)';
            break;
          case PilotRole.picus:
            colTarget = 'Col 24 (ME Day PICUS)';
            break;
          case PilotRole.copilot:
            colTarget = 'Col 25 (ME Day Copilot)';
            break;
        }
      } else {
        switch (_role) {
          case PilotRole.dual:
            colTarget = 'Col 26 (ME Night Dual)';
            break;
          case PilotRole.pic:
            colTarget = 'Col 27 (ME Night PIC)';
            break;
          case PilotRole.picus:
            colTarget = 'Col 28 (ME Night PICUS)';
            break;
          case PilotRole.copilot:
            colTarget = 'Col 29 (ME Night Copilot)';
            break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '32-Column Logbook Allocation Target:\n$colTarget: ${TimeUtils.formatMinutesToHhMm(durMins)}'
              '${_dayLandings > 0 ? " • Col 30: $_dayLandings Day Ldg" : ""}'
              '${_nightLandings > 0 ? " • Col 31: $_nightLandings Night Ldg" : ""}'
              '${_soloCrossCountry ? " • Solo XC (CAR 61.01.5)" : ""}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AircraftPicker extends StatefulWidget {
  final List<AircraftModel> models;
  const _AircraftPicker({required this.models});
  @override
  State<_AircraftPicker> createState() => _AircraftPickerState();
}

class _AircraftPickerState extends State<_AircraftPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final models = widget.models
        .where(
          (model) =>
              '${model.id} ${model.displayName}'.toLowerCase().contains(_query),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .65,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search aircraft',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            if (models.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No matching aircraft. Add models in Fleet.'),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final model in models)
                    ListTile(
                      title: Text(model.id),
                      subtitle: Text(model.displayName),
                      onTap: () => Navigator.pop(context, model),
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
