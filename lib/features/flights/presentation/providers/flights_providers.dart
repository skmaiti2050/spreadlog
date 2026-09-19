import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/flights_dao.dart';
import '../../data/flights_repository.dart';
import '../../domain/aircraft_type_summary.dart';
import '../../domain/flight.dart';
import '../../domain/ledger_calculator.dart';
import '../../domain/ledger_page.dart';
import '../../domain/ledger_totals.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final flightsDaoProvider = Provider<FlightsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.flightsDao;
});

final flightsRepositoryProvider = Provider<FlightsRepository>((ref) {
  final dao = ref.watch(flightsDaoProvider);
  return FlightsRepository(dao);
});

final ledgerCalculatorProvider = Provider<LedgerCalculator>((ref) {
  return const LedgerCalculator();
});

/// Reactive stream of all flights ordered by date descending.
final flightsStreamProvider = StreamProvider<List<Flight>>((ref) {
  final repository = ref.watch(flightsRepositoryProvider);
  return repository.watchAllFlights();
});

/// Real-time grand totals calculated from the current flight list.
final grandTotalsProvider = Provider<LedgerTotals>((ref) {
  final flightsAsync = ref.watch(flightsStreamProvider);
  final calculator = ref.watch(ledgerCalculatorProvider);

  return flightsAsync.when(
    data: (flights) => calculator.calculateTotals(flights),
    loading: () => LedgerTotals.zero,
    error: (err, stack) => LedgerTotals.zero,
  );
});

/// Real-time paginated physical logbook pages.
final ledgerPagesProvider = Provider<List<LedgerPage>>((ref) {
  final flightsAsync = ref.watch(flightsStreamProvider);
  final calculator = ref.watch(ledgerCalculatorProvider);

  return flightsAsync.when(
    data: (flights) => calculator.paginateLedger(flights),
    loading: () => [
      const LedgerPage(
        pageNumber: 1,
        entries: [],
        broughtForward: LedgerTotals.zero,
        pageTotals: LedgerTotals.zero,
        carriedForward: LedgerTotals.zero,
      ),
    ],
    error: (err, stack) => [],
  );
});

/// Real-time career totals broken down by aircraft type.
final aircraftTypeSummariesProvider =
    Provider<List<AircraftTypeSummary>>((ref) {
  final flightsAsync = ref.watch(flightsStreamProvider);
  final calculator = ref.watch(ledgerCalculatorProvider);

  return flightsAsync.when(
    data: (flights) => calculator.calculateTotalsByType(flights),
    loading: () => [],
    error: (err, stack) => [],
  );
});
