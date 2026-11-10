import 'package:flutter/material.dart';

import '../../../aircraft/domain/aircraft_model.dart';
import '../../domain/flight.dart';
import '../../domain/flight_filter.dart';
import '../../domain/flight_time.dart';

class FlightFilterDialog extends StatefulWidget {
  final FlightFilter initial;
  final List<Flight> flights;
  const FlightFilterDialog({
    super.key,
    required this.initial,
    required this.flights,
  });

  static Future<FlightFilter?> show(
    BuildContext context, {
    required FlightFilter initial,
    required List<Flight> flights,
  }) => showDialog<FlightFilter>(
    context: context,
    builder: (_) => FlightFilterDialog(initial: initial, flights: flights),
  );

  @override
  State<FlightFilterDialog> createState() => _FlightFilterDialogState();
}

class _FlightFilterDialogState extends State<FlightFilterDialog> {
  late Set<String> registrations;
  late Set<String> models;
  DateTime? start;
  DateTime? end;
  AircraftCategory? category;
  AircraftClass? aircraftClass;
  PilotRole? role;
  TimePeriod? period;
  FlightSort sort = FlightSort.newest;
  bool descending = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    registrations = {...initial.registrations};
    models = {...initial.modelIds};
    start = initial.startDate;
    end = initial.endDate;
    category = initial.category;
    aircraftClass = initial.aircraftClass;
    role = initial.role;
    period = initial.period;
    sort = initial.sort;
    descending = initial.descending;
  }

  Widget selection<T>(
    String label,
    List<T> values,
    T? value,
    String Function(T) name,
    void Function(T?) onChanged,
  ) => DropdownButtonFormField<T>(
    key: ValueKey('$label:$value'),
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<T>(child: const Text('Any')),
      for (final item in values)
        DropdownMenuItem(value: item, child: Text(name(item))),
    ],
    onChanged: (next) => setState(() => onChanged(next)),
  );

  @override
  Widget build(BuildContext context) {
    final registrationOptions =
        widget.flights.map((f) => f.registration).toSet().toList()..sort();
    final modelOptions =
        widget.flights
            .map((f) => f.aircraftModelId)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return AlertDialog(
      title: const Text('Filters & summary period'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final label in [
                    'All time',
                    'Last 12 months',
                    'Year to date',
                    'Up to date',
                  ])
                    ActionChip(
                      label: Text(label),
                      onPressed: () async {
                        final now = FlightFilter.day(DateTime.now());
                        if (label == 'Up to date') {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(1900),
                            lastDate: now,
                            initialDate: end ?? now,
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              start = null;
                              end = picked;
                            });
                          }
                        } else {
                          setState(() {
                            end = label == 'All time' ? null : now;
                            start = switch (label) {
                              'Last 12 months' => FlightFilter.yearBefore(now),
                              'Year to date' => DateTime(now.year),
                              _ => null,
                            };
                          });
                        }
                      },
                    ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  start == null && end == null
                      ? 'Custom date range'
                      : FlightFilter(
                          startDate: start,
                          endDate: end,
                        ).periodLabel,
                ),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDateRange: start != null && end != null
                        ? DateTimeRange(start: start!, end: end!)
                        : null,
                  );
                  if (range != null && mounted) {
                    setState(() {
                      start = range.start;
                      end = range.end;
                    });
                  }
                },
              ),
              const Text('Registrations (select any)'),
              Wrap(
                spacing: 4,
                children: [
                  for (final value in registrationOptions)
                    FilterChip(
                      label: Text(value),
                      selected: registrations.contains(value),
                      onSelected: (on) => setState(() {
                        on
                            ? registrations.add(value)
                            : registrations.remove(value);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Aircraft types (select any)'),
              Wrap(
                spacing: 4,
                children: [
                  for (final value in modelOptions)
                    FilterChip(
                      label: Text(value),
                      selected: models.contains(value),
                      onSelected: (on) => setState(() {
                        on ? models.add(value) : models.remove(value);
                      }),
                    ),
                ],
              ),
              selection(
                'Category',
                AircraftCategory.values,
                category,
                (v) => v.name,
                (v) => category = v,
              ),
              selection(
                'Engine class',
                AircraftClass.values,
                aircraftClass,
                (v) => v.name,
                (v) => aircraftClass = v,
              ),
              selection(
                'Pilot role',
                PilotRole.values,
                role,
                (v) => v.name,
                (v) => role = v,
              ),
              selection(
                'Day / night',
                TimePeriod.values,
                period,
                (v) => v.name,
                (v) => period = v,
              ),
              selection(
                'Sort',
                FlightSort.values,
                sort,
                (v) => v.name,
                (v) => sort = v ?? FlightSort.newest,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reverse sort order'),
                value: descending,
                onChanged: (v) => setState(() => descending = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const FlightFilter()),
          child: const Text('Clear all'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            FlightFilter(
              query: widget.initial.query,
              registrations: registrations,
              modelIds: models,
              startDate: start,
              endDate: end,
              category: category,
              aircraftClass: aircraftClass,
              role: role,
              period: period,
              sort: sort,
              descending: descending,
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
