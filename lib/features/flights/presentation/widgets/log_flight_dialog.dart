import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/instrument_time.dart';
import '../../domain/landings.dart';

/// Modal dialog for logging a flight with robust aviation validations,
/// SACAA syllabus templates, block time calculator, and smart auto-filling.
class LogFlightDialog extends ConsumerStatefulWidget {
  final Flight? initialFlight;

  const LogFlightDialog({super.key, this.initialFlight});

  static Future<Flight?> show(BuildContext context, {Flight? initialFlight}) {
    return showDialog<Flight>(
      context: context,
      builder: (context) => LogFlightDialog(initialFlight: initialFlight),
    );
  }

  @override
  ConsumerState<LogFlightDialog> createState() => _LogFlightDialogState();
}

class _LogFlightDialogState extends ConsumerState<LogFlightDialog> {
  final _formKey = GlobalKey<FormState>();

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
        _navaidsController = TextEditingController(text: init.instrumentTime!.navaids);
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
      lastDate: now, // Prevents logging future flights!
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _onRegChanged(String value) {
    String upper = value.toUpperCase().replaceAll(' ', '');
    // Auto-hyphenate South African registrations if typed without dash (e.g. ZSEXT -> ZS-EXT)
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
      } else if (type == 'BE76' || type == 'DA42' || type == 'PA34') {
        _aircraftClass = AircraftClass.multiEngine;
        _isFstd = false;
      } else {
        _aircraftClass = AircraftClass.singleEngine;
        _isFstd = false;
      }
    });
  }

  void _recalculateBlockTime() {
    final off = TimeUtils.tryParseHhMmToMinutes(_offBlocksController.text.trim());
    final on = TimeUtils.tryParseHhMmToMinutes(_onBlocksController.text.trim());
    if (off != null && on != null) {
      int diff = on - off;
      if (diff < 0) {
        diff += 24 * 60; // Flight crossed midnight
      }
      setState(() {
        _durationController.text = TimeUtils.formatMinutesToHhMm(diff);
      });
    }
  }

  void _appendAirfield(String code) {
    final current = _remarksController.text.trim();
    setState(() {
      if (current.isEmpty) {
        _remarksController.text = code;
      } else if (!current.contains(code)) {
        _remarksController.text = '$current - $code';
      }
    });
  }

  void _applySyllabusTemplate(String templateName) {
    setState(() {
      switch (templateName) {
        case 'PPL Solo XC':
          _typeController.text = 'C172';
          _aircraftClass = AircraftClass.singleEngine;
          _isFstd = false;
          _role = PilotRole.pic; // CAR 61.01.5: Solo XC must be PIC
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

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final durationMins =
        TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
    final instActualMins =
        TimeUtils.tryParseHhMmToMinutes(_instActualController.text.trim()) ?? 0;
    final instFstdMins =
        TimeUtils.tryParseHhMmToMinutes(_instFstdController.text.trim()) ?? 0;

    // Cross-field validation: Instrument actual cannot exceed total duration
    if (!_isFstd && instActualMins > durationMins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Actual instrument time cannot exceed total flight duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cross-field validation: Solo XC cannot be Dual
    if (_soloCrossCountry && _role == PilotRole.dual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Solo Cross-Country (CAR 61.01.5) cannot be logged as Dual'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
    final isDualWithSelf = _role == PilotRole.dual &&
        _picController.text.trim().toUpperCase() == 'SELF';

    return AlertDialog(
      title: Row(
        children: [
          Icon(_isEditing ? Icons.edit_note : Icons.flight_takeoff),
          const SizedBox(width: 8),
          Text(_isEditing ? 'Edit Flight Entry' : 'Log Flight Entry'),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SACAA Quick Syllabus Flight Templates
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
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'SACAA Syllabus Quick Templates:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _templateChip('PPL Solo XC', Icons.navigation_outlined),
                          _templateChip('Night Rating Dual', Icons.nightlight_outlined),
                          _templateChip('Multi-Engine Dual', Icons.flight),
                          _templateChip('IF Sim (FNPT II)', Icons.computer),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Date Picker Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 15),
                      label: const Text('Change Date'),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Aircraft Type & Registration
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          labelText: 'Type (e.g. C172)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                        onChanged: (v) {
                          final upper = v.trim().toUpperCase();
                          if (upper == 'BE76' || upper == 'DA42' || upper == 'PA34') {
                            setState(() {
                              _aircraftClass = AircraftClass.multiEngine;
                              _isFstd = false;
                            });
                          } else if (upper == 'FNPT II' || upper == 'SIM') {
                            setState(() => _isFstd = true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _regController,
                        decoration: const InputDecoration(
                          labelText: 'Registration (e.g. ZS-EXT)',
                          hintText: 'ZS-ABC',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: _onRegChanged,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 3) return 'Invalid reg';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Registration Prefix Helpers & Aircraft Type Chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      label: const Text('ZS- (Civil)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _regController.text = 'ZS-'),
                    ),
                    ActionChip(
                      label: const Text('ZU- (NTCA)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _regController.text = 'ZU-'),
                    ),
                    const SizedBox(width: 4),
                    ..._popularTypes.map((t) {
                      return ActionChip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _onTypeSelected(t),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 10),

                // PIC Name & Duration
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _picController,
                        decoration: const InputDecoration(
                          labelText: 'Pilot in Command (PIC)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (HH:MM)',
                          hintText: '01:30',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final mins = TimeUtils.tryParseHhMmToMinutes(v);
                          if (mins == null) return 'Format HH:MM';
                          if (mins <= 0) return 'Must be > 00:00';
                          if (mins > 960) return 'Exceeds 16 hours';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                // Dual Instruction Advisory Warning
                if (isDualWithSelf) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 13, color: theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Advisory: Dual instruction flights usually name the instructor as PIC.',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // Block Times Calculator (Optional)
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        _showBlockTimes ? Icons.expand_less : Icons.schedule,
                        size: 16,
                      ),
                      label: Text(
                        _showBlockTimes
                            ? 'Hide Block Times Calculator'
                            : 'Calculate Duration from Off/On Blocks',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => setState(() => _showBlockTimes = !_showBlockTimes),
                    ),
                  ],
                ),
                if (_showBlockTimes) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _offBlocksController,
                            decoration: const InputDecoration(
                              labelText: 'Off-Blocks (HH:MM)',
                              hintText: '14:15',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _recalculateBlockTime(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _onBlocksController,
                            decoration: const InputDecoration(
                              labelText: 'On-Blocks (HH:MM)',
                              hintText: '15:45',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => _recalculateBlockTime(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),

                // Class & FSTD toggle
                Row(
                  children: [
                    const Text('Class: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ChoiceChip(
                      label: const Text('Single Engine', style: TextStyle(fontSize: 11)),
                      selected: !_isFstd && _aircraftClass == AircraftClass.singleEngine,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _isFstd = false;
                            _aircraftClass = AircraftClass.singleEngine;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Multi Engine', style: TextStyle(fontSize: 11)),
                      selected: !_isFstd && _aircraftClass == AircraftClass.multiEngine,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _isFstd = false;
                            _aircraftClass = AircraftClass.multiEngine;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('FSTD/Sim', style: TextStyle(fontSize: 11)),
                      selected: _isFstd,
                      onSelected: (val) {
                        if (val) setState(() => _isFstd = true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Role & Period (only when not FSTD)
                if (!_isFstd) ...[
                  Row(
                    children: [
                      const Text('Role: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4,
                        children: PilotRole.values.map((r) {
                          return ChoiceChip(
                            label: Text(r.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            selected: _role == r,
                            onSelected: (s) {
                              if (s) {
                                setState(() {
                                  _role = r;
                                  if (r != PilotRole.pic && _soloCrossCountry) {
                                    _soloCrossCountry = false; // Solo XC must be PIC
                                  }
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Period: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('Day', style: TextStyle(fontSize: 11)),
                        selected: _period == TimePeriod.day,
                        onSelected: (s) {
                          if (s) setState(() => _period = TimePeriod.day);
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Night', style: TextStyle(fontSize: 11)),
                        selected: _period == TimePeriod.night,
                        onSelected: (s) {
                          if (s) setState(() => _period = TimePeriod.night);
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Landings (Clean Styled Dropdown FormFields with borders)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _dayLandings,
                        decoration: const InputDecoration(
                          labelText: 'Day Landings',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(
                          11,
                          (i) => DropdownMenuItem(value: i, child: Text('$i')),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _dayLandings = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _nightLandings,
                        decoration: const InputDecoration(
                          labelText: 'Night Landings',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(
                          11,
                          (i) => DropdownMenuItem(value: i, child: Text('$i')),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _nightLandings = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Solo Cross-Country Switch (CAR 61.01.5)
                SwitchListTile(
                  title: const Text('Solo Cross-Country (SACAA CAR 61.01.5)', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Must be flown as PIC. Required for SACAA licence renewal summaries.', style: TextStyle(fontSize: 11)),
                  value: _soloCrossCountry,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (v) {
                    setState(() {
                      _soloCrossCountry = v;
                      if (v && _role != PilotRole.pic) {
                        _role = PilotRole.pic; // Auto-select PIC
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Instrument Flying & Navaids (Clean Card with zero overlap!)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Instrument Flying & Navaids (Optional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _instActualController,
                              decoration: const InputDecoration(
                                labelText: 'Inst Actual (HH:MM)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                                if (instMins == null) return 'Format HH:MM';
                                final durMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
                                if (!_isFstd && instMins > durMins) {
                                  return 'Cannot exceed total flight ($durMins m)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _instFstdController,
                              decoration: const InputDecoration(
                                labelText: 'Inst FSTD (HH:MM)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final instMins = TimeUtils.tryParseHhMmToMinutes(v);
                                if (instMins == null) return 'Format HH:MM';
                                final durMins = TimeUtils.tryParseHhMmToMinutes(_durationController.text.trim()) ?? 0;
                                if (_isFstd && instMins > durMins) {
                                  return 'Cannot exceed sim session ($durMins m)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _navaidsController,
                        decoration: const InputDecoration(
                          labelText: 'Navaids / Approach',
                          hintText: 'e.g. ILS RWY 03, VOR, RNAV GNSS',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Remarks & Route
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Details / Remarks / Route (Column 5)',
                    hintText: 'e.g. FALA - FAGM Local Training',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),

                // Common South African Airfield Chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Text('Airfields: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ..._popularAirfields.map((af) {
                      return ActionChip(
                        label: Text(af['code']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        tooltip: af['name'],
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _appendAirfield(af['code']!),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Column Target Pill
                _buildLiveColumnPill(theme),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 18),
          onPressed: _onSave,
          label: Text(_isEditing ? 'Save Changes' : 'Log Flight'),
        ),
      ],
    );
  }

  Widget _templateChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      visualDensity: VisualDensity.compact,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined, size: 16, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recording to: $colTarget: ${TimeUtils.formatMinutesToHhMm(durMins)}'
              '${_dayLandings > 0 ? " • Col 30: $_dayLandings Day Ldg" : ""}'
              '${_nightLandings > 0 ? " • Col 31: $_nightLandings Night Ldg" : ""}'
              '${_soloCrossCountry ? " • Solo XC" : ""}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
