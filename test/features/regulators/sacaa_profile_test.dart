import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/flights/domain/flight.dart';
import 'package:aviation_logbook/features/flights/domain/flight_time.dart';
import 'package:aviation_logbook/features/flights/domain/landings.dart';
import 'package:aviation_logbook/features/regulators/domain/sacaa_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SacaaProfile Domain Tests', () {
    const profile = SacaaProfile();

    test('Profile identity and static properties match statutory standard', () {
      expect(profile.regulatorId, equals('sacaa'));
      expect(profile.country, equals('South Africa'));
      expect(profile.entriesPerPage, equals(14));
      expect(profile.getColumns().length, greaterThanOrEqualTo(32));
    });

    test('Pagination produces 14 entries per page adhering to SACAA layout', () {
      final now = DateTime(2026, 9, 18);
      final flights = List.generate(
        20,
        (index) => Flight(
          id: 'flight_$index',
          date: now.add(Duration(days: index)),
          registration: 'ZS-EXT',
          picName: 'SELF',
          flightTimes: const [
            FlightTime(
              aircraftClass: AircraftClass.singleEngine,
              period: TimePeriod.day,
              role: PilotRole.pic,
              durationMinutes: 60,
            ),
          ],
          landings: const Landings(dayCount: 1),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final pages = profile.paginate(flights);
      expect(pages.length, equals(2));
      expect(pages[0].entries.length, equals(14));
      expect(pages[1].entries.length, equals(6));

      // Check invariants
      expect(pages[0].broughtForward.totalFlightTimeMinutes, equals(0));
      expect(pages[0].pageTotals.seDayPic, equals(14 * 60));
      expect(pages[0].carriedForward.seDayPic, equals(14 * 60));

      expect(pages[1].broughtForward.seDayPic, equals(14 * 60));
      expect(pages[1].pageTotals.seDayPic, equals(6 * 60));
      expect(pages[1].carriedForward.seDayPic, equals(20 * 60));
    });
  });
}

