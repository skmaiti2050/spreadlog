import 'package:aviation_logbook/features/flights/data/entry_preferences.dart';
import 'package:aviation_logbook/features/flights/domain/registration_suggestion.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'preferred mode survives a new adapter and rejects unknown formats',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await const EntryPreferences().loadDurationMode(), 'hhMm');
      for (final mode in EntryPreferences.modes) {
        await const EntryPreferences().saveDurationMode(mode);
        expect(await const EntryPreferences().loadDurationMode(), mode);
      }
      await expectLater(
        const EntryPreferences().saveDurationMode('other'),
        throwsArgumentError,
      );
      SharedPreferences.setMockInitialValues({
        'flight_entry_duration_mode': 'old',
      });
      expect(await const EntryPreferences().loadDurationMode(), 'hhMm');
    },
  );
  test('registration suggestions use only matching flights and current Fleet details', () {
    final date = DateTime(2026);
    Flight flight(String id, String reg, String model, int day) => Flight(
      id: id,
      date: DateTime(2026, 1, day),
      registration: reg,
      aircraftModelId: model,
      picName: 'SELF',
      createdAt: date,
      updatedAt: date,
      flightTimes: const [
        FlightTime(
          aircraftClass: AircraftClass.singleEngine,
          period: TimePeriod.night,
          role: PilotRole.dual,
          durationMinutes: 90,
        ),
      ],
    );
    final flights = [
      flight('old', 'ZS-ABC', 'C172', 1),
      flight('latest', 'zs-abc', 'DA42', 2),
      flight('unrelated', 'ZS-XYZ', 'BE76', 3),
    ];
    const fleet = [
      AircraftModel(
        id: 'DA42',
        manufacturer: 'Diamond',
        model: 'DA42',
        aircraftClass: AircraftClass.multiEngine,
        category: AircraftCategory.aeroplane,
      ),
    ];
    final suggestion = RegistrationSuggestion.find(
      registration: ' zs abc ',
      flights: flights,
      fleet: fleet,
    );
    expect(suggestion?.modelId, 'DA42');
    expect(suggestion?.aircraftClass, AircraftClass.multiEngine);
    expect(
      RegistrationSuggestion.find(
        registration: 'ZS-',
        flights: flights,
        fleet: fleet,
      ),
      isNull,
    );
    expect(
      RegistrationSuggestion.find(
        registration: 'ZS-NEW',
        flights: flights,
        fleet: fleet,
      ),
      isNull,
    );
    expect(
      RegistrationSuggestion.find(
        registration: 'ZS-ABC',
        flights: flights,
        fleet: fleet,
        excludingId: 'latest',
      )?.modelId,
      'C172',
    );
    expect(
      RegistrationSuggestion.find(
        registration: 'ZS-ABC',
        flights: [],
        fleet: fleet,
      ),
      isNull,
    );
  });
}
