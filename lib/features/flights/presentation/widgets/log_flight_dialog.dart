import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/instrument_time.dart';
import '../../domain/landings.dart';

/// Modal dialog for logging a flight with clean layout, smart defaults,
/// SACAA syllabus templates, and auto-filling features.
class LogFlightDialog extends ConsumerStatefulWidget {
  const LogFlightDialog({super.key});

  static Future<Flight?> show(BuildContext context) {
    return showDialog<Flight>(
      context: context,
      builder: (context) => const LogFlightDialog(),
    );
  }

  @override
  ConsumerState<LogFlightDialog> createState() => _LogFlightDialogState();
}

class _LogFlightDialogState extends ConsumerState<LogFlightDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _date = DateTime.now();
  late final TextEditingController _typeController;
  final _regController = TextEditingController(text: 'ZS-');
  late final TextEditingController _picController;
  final _durationController = TextEditingController(text: '01:30');
  final _remarksController = TextEditingController(text: 'Local Training');

  AircraftClass _aircraftClass = AircraftClass.singleEngine;
  PilotRole _role = PilotRole.pic;
  TimePeriod _period = TimePeriod.day;
  bool _isFstd = false;
  bool _soloCrossCountry = false;

  int _dayLandings = 1;
  int _nightLandings = 0;

  final _instActualController = TextEditingController(text: '00:00');
  final _instFstdController = TextEditingController(text: '00:00');
  final _navaidsController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    final profile = ref.read(pilotProfileProvider);
    _typeController = TextEditingController(text: 'C172');
    _picController = TextEditingController(
      text: profile.defaultPicName.isNotEmpty ? profile.defaultPicName : 'SELF',
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _regController.dispose();
    _picController.dispose();
    _durationController.dispose();
    _remarksController.dispose();
    _instActualController.dispose();
    _instFstdController.dispose();
    _navaidsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
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
          _remarksController.text = 'FALA Night Circuits & Navigation';
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
          _remarksController.text = 'FAGM Asymmetric & General Handling';
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
          _remarksController.text = 'Instrument Rating FSTD Procedures';
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

    final now = DateTime.now();
    final flightId = 'flight_${now.millisecondsSinceEpoch}';

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
      createdAt: now,
      updatedAt: now,
    );

    Navigator.of(context).pop(flight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return AlertDialog(
      title: const Text('Log Flight Entry'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SACAA Quick Syllabus Flight Templates
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
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
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
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
                    // SA prefix quick buttons
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
                          if (TimeUtils.tryParseHhMmToMinutes(v) == null) {
                            return 'Format HH:MM';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                              if (s) setState(() => _role = r);
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

                // Solo Cross-Country Switch
                SwitchListTile(
                  title: const Text('Solo Cross-Country (SACAA CAR 61.01.5)', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Required for PPL/CPL license issue summaries', style: TextStyle(fontSize: 11)),
                  value: _soloCrossCountry,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (v) => setState(() => _soloCrossCountry = v),
                ),
                const SizedBox(height: 10),

                // Instrument Flying & Navaids (Clean Card - NO overlap or clipping!)
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

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Details / Remarks (Column 5)',
                    hintText: 'e.g. FALA - FAGM Local Training',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
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
        FilledButton(
          onPressed: _onSave,
          child: const Text('Log Flight'),
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
}
