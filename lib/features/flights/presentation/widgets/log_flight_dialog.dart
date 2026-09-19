import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/hint_banner.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/instrument_time.dart';
import '../../domain/landings.dart';

/// Progressive multi-step card modal for logging flights.
/// Adapts seamlessly from ultra-narrow 320px mobile screens to spacious desktop tablets.
class LogFlightDialog extends ConsumerStatefulWidget {
  final Flight? initialFlight;
  final bool isFullScreen;

  const LogFlightDialog({
    super.key,
    this.initialFlight,
    this.isFullScreen = false,
  });

  static Future<Flight?> show(BuildContext context, {Flight? initialFlight}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Navigator.of(context).push<Flight>(
        MaterialPageRoute<Flight>(
          fullscreenDialog: true,
          builder: (context) => LogFlightDialog(
            initialFlight: initialFlight,
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
            isFullScreen: false,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LogFlightDialog> createState() => _LogFlightDialogState();
}

class _LogFlightDialogState extends ConsumerState<LogFlightDialog> {
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

  // Block time calculator
  bool _showBlockTimes = false;
  final _offBlocksController = TextEditingController();
  final _onBlocksController = TextEditingController();

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

  static const List<String> _popularTypes = [
    'C172',
    'C152',
    'PA28',
    'BE76',
    'DA42',
    'PA34',
    'SR22',
    'FNPT II',
  ];

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
    final profile = ref.read(pilotProfileProvider);
    final init = widget.initialFlight;

    if (init != null) {
      _date = init.date;
      _typeController = TextEditingController(text: init.aircraftModelId ?? 'C172');
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
          text: TimeUtils.formatMinutesToHhMm(init.instrumentTime!.actualMinutes),
        );
        _instFstdController = TextEditingController(
          text: TimeUtils.formatMinutesToHhMm(init.instrumentTime!.fstdMinutes),
        );
        _navaidsController = TextEditingController(text: init.instrumentTime!.navaids ?? '');
      } else {
        _instActualController = TextEditingController(text: '00:00');
        _instFstdController = TextEditingController(text: '00:00');
        _navaidsController = TextEditingController();
      }
    } else {
      _typeController = TextEditingController(text: 'C172');
      _regController = TextEditingController(text: 'ZS-');
      _picController = TextEditingController(
        text: profile.defaultPicName.isNotEmpty ? profile.defaultPicName : 'SELF',
      );
      _durationController = TextEditingController(text: '01:30');
      _remarksController = TextEditingController(text: 'Local Training');
      _instActualController = TextEditingController(text: '00:00');
      _instFstdController = TextEditingController(text: '00:00');
      _navaidsController = TextEditingController();
    }
  }

  @override
  void dispose() {
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
      setState(() => _date = picked);
    }
  }

  void _onRegChanged(String value) {
    String upper = value.toUpperCase().replaceAll(' ', '');
    if (upper.length >= 3 && !upper.contains('-')) {
      if (upper.startsWith('ZS') || upper.startsWith('ZU') || upper.startsWith('ZT')) {
        upper = '${upper.substring(0, 2)}-${upper.substring(2)}';
        _regController.value = TextEditingValue(
          text: upper,
          selection: TextSelection.collapsed(offset: upper.length),
        );
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

  void _onTypeSelected(String type) {
    setState(() {
      _typeController.text = type;
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
            content: Text('Calculated flight time: ${TimeUtils.formatMinutesToHhMm(diff)} ($diff mins)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _applySyllabusTemplate(String templateName) {
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
            content: Text('Error: Solo Cross-Country (CAR 61.01.5) cannot be logged as Dual'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      return true;
    } else if (step == 2) {
      if (!(_formKeyStep3.currentState?.validate() ?? true)) return false;
      final durationMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
      final instActualMins = TimeUtils.tryParseHhMmToMinutes(_instActualController.text.trim()) ?? 0;
      if (!_isFstd && instActualMins > durationMins) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Actual instrument time cannot exceed total flight duration'),
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
        _onSave();
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

  void _onSave() {
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) return;

    final durationMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    final instActualMins =
        TimeUtils.tryParseHhMmToMinutes(_instActualController.text.trim()) ?? 0;
    final instFstdMins =
        TimeUtils.tryParseHhMmToMinutes(_instFstdController.text.trim()) ?? 0;

    final now = DateTime.now();
    final flightId = widget.initialFlight?.id ?? 'flight_${now.millisecondsSinceEpoch}';
    final createdAt = widget.initialFlight?.createdAt ?? now;

    final flight = Flight(
      id: flightId,
      date: _date,
      aircraftModelId: _typeController.text.trim().toUpperCase(),
      registration: _regController.text.trim().toUpperCase(),
      picName: _picController.text.trim().toUpperCase(),
      remarks: _remarksController.text.trim(),
      soloCrossCountry: _soloCrossCountry,
      fstdActualMinutes: _isFstd ? durationMins : 0,
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
      instrumentTime: (instActualMins > 0 ||
              instFstdMins > 0 ||
              _navaidsController.text.isNotEmpty)
          ? InstrumentTime(
              navaids: _navaidsController.text.trim(),
              actualMinutes: instActualMins,
              fstdMinutes: instFstdMins,
            )
          : null,
      landings: Landings(
        dayCount: _dayLandings,
        nightCount: _nightLandings,
      ),
      createdAt: createdAt,
      updatedAt: now,
    );

    Navigator.of(context).pop(flight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isEditing ? 'Edit Flight Entry' : 'Log Flight Entry';

    final bodyContent = Column(
      children: [
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
    );

    if (widget.isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(child: bodyContent),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: bodyContent,
    );
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
              backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Aircraft(ThemeData theme) {
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'SACAA Syllabus Quick Fill',
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
                      _templateChip('Night Rating Dual', Icons.nightlight_round),
                      _templateChip('Multi-Engine Dual', Icons.airplanemode_active),
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
                child: Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Aircraft Model
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Aircraft Model / Type',
                hintText: 'e.g. C172, BE76, FNPT II',
                prefixIcon: Icon(Icons.airplanemode_active, size: 18),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: _onTypeSelected,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: _popularTypes.map((type) {
                return ChoiceChip(
                  label: Text(type, style: const TextStyle(fontSize: 10)),
                  selected: _typeController.text.toUpperCase() == type,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onSelected: (_) => _onTypeSelected(type),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: _onRegChanged,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                ActionChip(
                  label: const Text('ZS- (Standard)', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _onRegChanged('ZS-'),
                ),
                ActionChip(
                  label: const Text('ZU- (NTCA)', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _onRegChanged('ZU-'),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              message: 'Tap the calculator icon (🖩) next to Duration to compute flight time from Off/On block times.',
            ),
            // Flight Duration
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: _isFstd ? 'FSTD Actual Time (Col 13)' : 'Total Flight Duration',
                      hintText: 'HH:MM or 1.5',
                      prefixIcon: const Icon(Icons.schedule, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(_showBlockTimes ? Icons.calculate : Icons.calculate_outlined, size: 20),
                        tooltip: 'Calculate from Off/On Blocks',
                        onPressed: () => setState(() => _showBlockTimes = !_showBlockTimes),
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

            // Block Time Calculator Dropdown
            if (_showBlockTimes) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Block Time Calculator', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _offBlocksController,
                            decoration: const InputDecoration(labelText: 'Off Blocks', hintText: '09:00', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _onBlocksController,
                            decoration: const InputDecoration(labelText: 'On Blocks', hintText: '10:30', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _applyBlockTimes,
                          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

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
                      const SizedBox(height: 4),
                      SegmentedButton<AircraftClass>(
                        segments: const [
                          ButtonSegment(value: AircraftClass.singleEngine, label: Text('SE', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: AircraftClass.multiEngine, label: Text('ME', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_aircraftClass},
                        onSelectionChanged: _isFstd ? null : (s) => setState(() => _aircraftClass = s.first),
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
                      const SizedBox(height: 4),
                      SegmentedButton<TimePeriod>(
                        segments: const [
                          ButtonSegment(value: TimePeriod.day, label: Text('Day', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: TimePeriod.night, label: Text('Night', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_period},
                        onSelectionChanged: _isFstd ? null : (s) => setState(() => _period = s.first),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Operating Role
            Text(
              'Pilot Operating Role',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SegmentedButton<PilotRole>(
              segments: const [
                ButtonSegment(value: PilotRole.dual, label: Text('DUAL', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: PilotRole.pic, label: Text('PIC', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: PilotRole.picus, label: Text('PICUS', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: PilotRole.copilot, label: Text('COPILOT', style: TextStyle(fontSize: 10))),
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
            const SizedBox(height: 14),

            // Landings
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayLandings,
                    decoration: const InputDecoration(labelText: 'Day Landings (Col 30)', border: OutlineInputBorder(), isDense: true),
                    items: List.generate(21, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (v) => setState(() => _dayLandings = v ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _nightLandings,
                    decoration: const InputDecoration(labelText: 'Night Landings (Col 31)', border: OutlineInputBorder(), isDense: true),
                    items: List.generate(21, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (v) => setState(() => _nightLandings = v ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Solo Cross-Country (CAR 61.01.5)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo Cross-Country (CAR 61.01.5)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Must be flown as PIC. Required for SACAA licence renewal.', style: TextStyle(fontSize: 11)),
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

  Widget _buildStep3InstrumentAndReview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HintBanner(
              hintKey: 'hint_step3_sacaa_audit',
              message: 'Tap airport chips to append to your route. The live banner at the bottom audits your SACAA column tally.',
            ),
            // Instrument Flying Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Instrument Flying & Navaids (Optional)', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _instActualController,
                          decoration: const InputDecoration(labelText: 'Actual Inst (Col 9)', hintText: '00:00', border: OutlineInputBorder(), isDense: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                            if (instMins == null) return 'HH:MM';
                            final durMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
                            if (!_isFstd && instMins > durMins) return 'Exceeds flight ($durMins m)';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _instFstdController,
                          decoration: const InputDecoration(labelText: 'FSTD / Sim (Col 10)', hintText: '00:00', border: OutlineInputBorder(), isDense: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                            if (instMins == null) return 'HH:MM';
                            final durMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
                            if (_isFstd && instMins > durMins) return 'Exceeds sim ($durMins m)';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _navaidsController,
                    decoration: const InputDecoration(labelText: 'Navaids / Approaches (Col 11)', hintText: 'e.g. ILS RWY 03, VOR, RNAV', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Remarks & Route
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Route & Remarks (Column 5)', hintText: 'e.g. FALA - FAGM Local Training', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_airport_outlined, size: 14, color: theme.colorScheme.primary),
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
                  label: Text(af['code']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  tooltip: af['name'],
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => _appendAirfield(af['code']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Live SACAA 32-Column Allocation Badge
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
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
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
            icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 16),
            label: Text(_currentStep == 2 ? (_isEditing ? 'Save Changes' : 'Log Flight') : 'Next'),
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

  Widget _buildLiveColumnPill(ThemeData theme) {
    final durMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    String colTarget;

    if (_isFstd) {
      colTarget = 'Col 13 (FSTD Actual)';
    } else if (_aircraftClass == AircraftClass.singleEngine) {
      if (_period == TimePeriod.day) {
        switch (_role) {
          case PilotRole.dual: colTarget = 'Col 14 (SE Day Dual)'; break;
          case PilotRole.pic: colTarget = 'Col 15 (SE Day PIC)'; break;
          case PilotRole.picus: colTarget = 'Col 16 (SE Day PICUS)'; break;
          case PilotRole.copilot: colTarget = 'Col 17 (SE Day Copilot)'; break;
        }
      } else {
        switch (_role) {
          case PilotRole.dual: colTarget = 'Col 18 (SE Night Dual)'; break;
          case PilotRole.pic: colTarget = 'Col 19 (SE Night PIC)'; break;
          case PilotRole.picus: colTarget = 'Col 20 (SE Night PICUS)'; break;
          case PilotRole.copilot: colTarget = 'Col 21 (SE Night Copilot)'; break;
        }
      }
    } else {
      if (_period == TimePeriod.day) {
        switch (_role) {
          case PilotRole.dual: colTarget = 'Col 22 (ME Day Dual)'; break;
          case PilotRole.pic: colTarget = 'Col 23 (ME Day PIC)'; break;
          case PilotRole.picus: colTarget = 'Col 24 (ME Day PICUS)'; break;
          case PilotRole.copilot: colTarget = 'Col 25 (ME Day Copilot)'; break;
        }
      } else {
        switch (_role) {
          case PilotRole.dual: colTarget = 'Col 26 (ME Night Dual)'; break;
          case PilotRole.pic: colTarget = 'Col 27 (ME Night PIC)'; break;
          case PilotRole.picus: colTarget = 'Col 28 (ME Night PICUS)'; break;
          case PilotRole.copilot: colTarget = 'Col 29 (ME Night Copilot)'; break;
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
          Icon(Icons.table_chart_outlined, size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SACAA 32-Column Allocation Target:\n$colTarget: ${TimeUtils.formatMinutesToHhMm(durMins)}'
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
