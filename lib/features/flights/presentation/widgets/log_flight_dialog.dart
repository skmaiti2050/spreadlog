import 'package:flutter/material.dart';

import '../../../../core/utils/time_utils.dart';
import '../../../aircraft/domain/aircraft_model.dart';
import '../../domain/flight.dart';
import '../../domain/flight_time.dart';
import '../../domain/instrument_time.dart';
import '../../domain/landings.dart';

/// Modal dialog for logging a flight with clean smart defaults.
class LogFlightDialog extends StatefulWidget {
  const LogFlightDialog({super.key});

  static Future<Flight?> show(BuildContext context) {
    return showDialog<Flight>(
      context: context,
      builder: (context) => const LogFlightDialog(),
    );
  }

  @override
  State<LogFlightDialog> createState() => _LogFlightDialogState();
}

class _LogFlightDialogState extends State<LogFlightDialog> {
  final _formKey = GlobalKey<FormState>();

  DateTime _date = DateTime.now();
  final _typeController = TextEditingController(text: 'C172');
  final _regController = TextEditingController(text: 'ZS-EXT');
  final _picController = TextEditingController(text: 'SELF');
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
    'FNPT II',
  ];

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
                // Date picker row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Change'),
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

                // Quick aircraft type suggestion chips
                Wrap(
                  spacing: 4,
                  children: _popularTypes.map((t) {
                    return ActionChip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _typeController.text = t;
                          if (t == 'FNPT II') {
                            _isFstd = true;
                          } else if (t == 'BE76' || t == 'DA42') {
                            _aircraftClass = AircraftClass.multiEngine;
                            _isFstd = false;
                          } else {
                            _aircraftClass = AircraftClass.singleEngine;
                            _isFstd = false;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

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
                    const Text('Class: ', style: TextStyle(fontSize: 12)),
                    ChoiceChip(
                      label: const Text('Single Engine', style: TextStyle(fontSize: 11)),
                      selected: !_isFstd && _aircraftClass == AircraftClass.singleEngine,
                      onSelected: (val) {
                        if (val) setState(() { _isFstd = false; _aircraftClass = AircraftClass.singleEngine; });
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Multi Engine', style: TextStyle(fontSize: 11)),
                      selected: !_isFstd && _aircraftClass == AircraftClass.multiEngine,
                      onSelected: (val) {
                        if (val) setState(() { _isFstd = false; _aircraftClass = AircraftClass.multiEngine; });
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
                      const Text('Role: ', style: TextStyle(fontSize: 12)),
                      Wrap(
                        spacing: 4,
                        children: PilotRole.values.map((r) {
                          final label = r.name.toUpperCase();
                          return ChoiceChip(
                            label: Text(label, style: const TextStyle(fontSize: 10)),
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
                      const Text('Period: ', style: TextStyle(fontSize: 12)),
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

                // Landings & Solo XC
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Day Ldg: '),
                          DropdownButton<int>(
                            value: _dayLandings,
                            items: List.generate(
                              11,
                              (i) => DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _dayLandings = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Night Ldg: '),
                          DropdownButton<int>(
                            value: _nightLandings,
                            items: List.generate(
                              11,
                              (i) => DropdownMenuItem(value: i, child: Text('$i')),
                            ),
                            onChanged: (v) {
                              if (v != null) setState(() => _nightLandings = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  title: const Text('Solo Cross-Country (CAR 61.01.5)'),
                  value: _soloCrossCountry,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (v) => setState(() => _soloCrossCountry = v ?? false),
                ),
                const SizedBox(height: 8),

                // Instrument Time (Accordion/Collapsible or clean inputs)
                ExpansionTile(
                  title: const Text(
                    'Instrument Flying & Navaids (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  tilePadding: EdgeInsets.zero,
                  children: [
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
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _navaidsController,
                      decoration: const InputDecoration(
                        labelText: 'Navaids / Approach',
                        hintText: 'e.g. ILS, VOR, RNAV',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 8),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Details / Remarks (Col 5)',
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
}

