import '../../aircraft/domain/aircraft_model.dart';
import 'aircraft_type_summary.dart';
import 'flight.dart';
import 'flight_time.dart';
import 'instruction_time.dart';
import 'ledger_page.dart';
import 'ledger_totals.dart';

/// Pure Dart Aviation Ledger Calculation Engine.
///
/// Has NO dependencies on Flutter widgets, Riverpod, Drift, or platform APIs.
/// All durations are calculated using integer minutes to avoid floating-point drift.
class LedgerCalculator {
  const LedgerCalculator();

  /// Calculates totals for an individual flight.
  LedgerTotals calculateFlightTotals(Flight flight) {
    int seDayDual = 0;
    int seDayPic = 0;
    int seDayPicus = 0;
    int seDayCopilot = 0;

    int seNightDual = 0;
    int seNightPic = 0;
    int seNightPicus = 0;
    int seNightCopilot = 0;

    int meDayDual = 0;
    int meDayPic = 0;
    int meDayPicus = 0;
    int meDayCopilot = 0;

    int meNightDual = 0;
    int meNightPic = 0;
    int meNightPicus = 0;
    int meNightCopilot = 0;

    for (final ft in flight.flightTimes) {
      if (ft.aircraftClass == AircraftClass.singleEngine) {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual:
              seDayDual += ft.durationMinutes;
            case PilotRole.pic:
              seDayPic += ft.durationMinutes;
            case PilotRole.picus:
              seDayPicus += ft.durationMinutes;
            case PilotRole.copilot:
              seDayCopilot += ft.durationMinutes;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual:
              seNightDual += ft.durationMinutes;
            case PilotRole.pic:
              seNightPic += ft.durationMinutes;
            case PilotRole.picus:
              seNightPicus += ft.durationMinutes;
            case PilotRole.copilot:
              seNightCopilot += ft.durationMinutes;
          }
        }
      } else {
        if (ft.period == TimePeriod.day) {
          switch (ft.role) {
            case PilotRole.dual:
              meDayDual += ft.durationMinutes;
            case PilotRole.pic:
              meDayPic += ft.durationMinutes;
            case PilotRole.picus:
              meDayPicus += ft.durationMinutes;
            case PilotRole.copilot:
              meDayCopilot += ft.durationMinutes;
          }
        } else {
          switch (ft.role) {
            case PilotRole.dual:
              meNightDual += ft.durationMinutes;
            case PilotRole.pic:
              meNightPic += ft.durationMinutes;
            case PilotRole.picus:
              meNightPicus += ft.durationMinutes;
            case PilotRole.copilot:
              meNightCopilot += ft.durationMinutes;
          }
        }
      }
    }

    int instructorSe = 0;
    int instructorMe = 0;
    int instructorFstd = 0;

    for (final it in flight.instructionTimes) {
      switch (it.category) {
        case InstructorCategory.singleEngine:
          instructorSe += it.durationMinutes;
        case InstructorCategory.multiEngine:
          instructorMe += it.durationMinutes;
        case InstructorCategory.fstd:
          instructorFstd += it.durationMinutes;
      }
    }

    final instrumentActual = flight.instrumentTime?.actualMinutes ?? 0;
    final instrumentFstd = flight.instrumentTime?.fstdMinutes ?? 0;

    final soloCrossCountryMinutes = flight.soloCrossCountry
        ? flight.totalDurationMinutes
        : 0;
    final soloCrossCountryCount = flight.soloCrossCountry ? 1 : 0;

    return LedgerTotals(
      seDayDual: seDayDual,
      seDayPic: seDayPic,
      seDayPicus: seDayPicus,
      seDayCopilot: seDayCopilot,
      seNightDual: seNightDual,
      seNightPic: seNightPic,
      seNightPicus: seNightPicus,
      seNightCopilot: seNightCopilot,
      meDayDual: meDayDual,
      meDayPic: meDayPic,
      meDayPicus: meDayPicus,
      meDayCopilot: meDayCopilot,
      meNightDual: meNightDual,
      meNightPic: meNightPic,
      meNightPicus: meNightPicus,
      meNightCopilot: meNightCopilot,
      instrumentActual: instrumentActual,
      instrumentFstd: instrumentFstd,
      instructorSe: instructorSe,
      instructorMe: instructorMe,
      instructorFstd: instructorFstd,
      fstdActual: flight.fstdActualMinutes,
      landingsDay: flight.landings.dayCount,
      landingsNight: flight.landings.nightCount,
      soloCrossCountryMinutes: soloCrossCountryMinutes,
      soloCrossCountryCount: soloCrossCountryCount,
    );
  }

  /// Calculates accumulated totals for an arbitrary collection of flights,
  /// with optional inclusive [startDate] and inclusive [cutoffDate].
  LedgerTotals calculateTotals(
    Iterable<Flight> flights, {
    DateTime? startDate,
    DateTime? cutoffDate,
  }) {
    var accumulated = LedgerTotals.zero;

    for (final flight in flights) {
      if (startDate != null && flight.date.isBefore(startDate)) {
        continue;
      }
      if (cutoffDate != null && flight.date.isAfter(cutoffDate)) {
        continue;
      }
      accumulated += calculateFlightTotals(flight);
    }

    return accumulated;
  }

  /// Paginates flights according to physical logbook page size (default 30 lines per page, as printed in the SACAA logbook).
  ///
  /// Maintains strict invariant:
  /// on each page: carriedForward == broughtForward + pageTotals
  List<LedgerPage> paginateLedger(
    List<Flight> flights, {
    int entriesPerPage = 30,
    LedgerTotals initialBroughtForward = LedgerTotals.zero,
  }) {
    assert(entriesPerPage > 0, 'entriesPerPage must be greater than zero');

    if (flights.isEmpty) {
      return [
        LedgerPage(
          pageNumber: 1,
          entries: const [],
          broughtForward: initialBroughtForward,
          pageTotals: LedgerTotals.zero,
          carriedForward: initialBroughtForward,
        ),
      ];
    }

    // Ensure flights are sorted chronologically
    final sortedFlights = List<Flight>.from(flights)
      ..sort((a, b) => a.date.compareTo(b.date));

    final pages = <LedgerPage>[];
    var currentBroughtForward = initialBroughtForward;
    var pageNumber = 1;

    for (var i = 0; i < sortedFlights.length; i += entriesPerPage) {
      final end = (i + entriesPerPage < sortedFlights.length)
          ? i + entriesPerPage
          : sortedFlights.length;
      final pageEntries = sortedFlights.sublist(i, end);
      final pageTotals = calculateTotals(pageEntries);
      final carriedForward = currentBroughtForward + pageTotals;

      pages.add(
        LedgerPage(
          pageNumber: pageNumber,
          entries: pageEntries,
          broughtForward: currentBroughtForward,
          pageTotals: pageTotals,
          carriedForward: carriedForward,
        ),
      );

      currentBroughtForward = carriedForward;
      pageNumber++;
    }

    return pages;
  }

  /// Calculates rolling 12-month summary for SACAA CAR 61.01.5(13) compliance.
  LedgerTotals calculateRolling12Months(
    Iterable<Flight> flights, {
    required DateTime asOfDate,
  }) {
    // 12 months immediately preceding the application date
    final startDate = DateTime(asOfDate.year - 1, asOfDate.month, asOfDate.day);
    return calculateTotals(flights, startDate: startDate, cutoffDate: asOfDate);
  }

  /// Calculates career totals grouped by aircraft type/model.
  ///
  /// Extracts the aircraft type identifier from [Flight.aircraftModelId]
  /// (defaulting to 'AIRCRAFT' if not specified), accumulates [LedgerTotals]
  /// per type, tracks [dateLastFlown], and returns a list sorted alphabetically.
  List<AircraftTypeSummary> calculateTotalsByType(Iterable<Flight> flights) {
    final Map<String, LedgerTotals> typeTotals = {};
    final Map<String, DateTime> lastFlownMap = {};

    for (final flight in flights) {
      final type = (flight.aircraftModelId != null &&
              flight.aircraftModelId!.trim().isNotEmpty)
          ? flight.aircraftModelId!.trim()
          : 'AIRCRAFT';

      final flightTotals = calculateFlightTotals(flight);
      typeTotals[type] = (typeTotals[type] ?? LedgerTotals.zero) + flightTotals;

      final existingDate = lastFlownMap[type];
      if (existingDate == null || flight.date.isAfter(existingDate)) {
        lastFlownMap[type] = flight.date;
      }
    }

    final summaries = typeTotals.entries.map((entry) {
      return AircraftTypeSummary(
        aircraftType: entry.key,
        totals: entry.value,
        dateLastFlown: lastFlownMap[entry.key],
      );
    }).toList();

    summaries.sort((a, b) => a.aircraftType.compareTo(b.aircraftType));
    return summaries;
  }
}

