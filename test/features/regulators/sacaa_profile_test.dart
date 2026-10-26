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
      // The printed SACAA logbook has 30 lines per page.
      expect(profile.entriesPerPage, equals(30));
      expect(profile.getColumns(), hasLength(greaterThanOrEqualTo(32)));
    });

    test('Column numbers follow SA-CATS 61 Appendix A', () {
      final titles = {
        for (final c in profile.getColumns()) c.columnNumber: c.title,
      };
      expect(titles, containsPair(6, 'Inst Navaids'));
      expect(titles, containsPair(7, 'Inst Place'));
      expect(titles, containsPair(8, 'Inst Actual'));
      expect(titles, containsPair(9, 'Inst FSTD'));
      expect(titles, containsPair(13, 'FSTD Actual'));
      expect(titles, containsPair(15, 'SE PIC Day'));
      expect(titles, containsPair(30, 'Landings Day'));
      expect(titles, containsPair(31, 'Landings Night'));
    });

    test('Pagination produces 30 entries per page adhering to SACAA layout', () {
      final now = DateTime(2026, 9, 18);
      final flights = List.generate(
        40,
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
      expect(pages, hasLength(2));
      expect(pages[0].entries, hasLength(30));
      expect(pages[1].entries, hasLength(10));

      // Check invariants
      expect(pages[0].broughtForward.totalFlightTimeMinutes, equals(0));
      expect(pages[0].pageTotals.seDayPic, equals(30 * 60));
      expect(pages[0].carriedForward.seDayPic, equals(30 * 60));

      expect(pages[1].broughtForward.seDayPic, equals(30 * 60));
      expect(pages[1].pageTotals.seDayPic, equals(10 * 60));
      expect(pages[1].carriedForward.seDayPic, equals(40 * 60));
    });
  });
}
