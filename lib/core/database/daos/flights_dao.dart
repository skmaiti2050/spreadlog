import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/aircraft_models_table.dart';
import '../tables/flight_times_table.dart';
import '../tables/flights_table.dart';
import '../tables/instruction_times_table.dart';
import '../tables/instrument_times_table.dart';
import '../tables/landings_table.dart';

part 'flights_dao.g.dart';

@DriftAccessor(tables: [
  FlightsTable,
  FlightTimesTable,
  InstrumentTimesTable,
  InstructionTimesTable,
  LandingsTable,
  AircraftModelsTable,
])
class FlightsDao extends DatabaseAccessor<AppDatabase> with _$FlightsDaoMixin {
  FlightsDao(super.db);

  /// Selects all flights ordered by date descending (newest first).
  Future<List<FlightsTableData>> getAllFlights() {
    return (select(flightsTable)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  /// Watches all flights ordered by date descending.
  Stream<List<FlightsTableData>> watchAllFlights() {
    return (select(flightsTable)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  /// Gets flight times for a flight.
  Future<List<FlightTimesTableData>> getFlightTimes(String flightId) {
    return (select(flightTimesTable)..where((t) => t.flightId.equals(flightId))).get();
  }

  /// Gets instrument time entry for a flight.
  Future<InstrumentTimesTableData?> getInstrumentTime(String flightId) {
    return (select(instrumentTimesTable)..where((t) => t.flightId.equals(flightId)))
        .getSingleOrNull();
  }

  /// Gets instruction times for a flight.
  Future<List<InstructionTimesTableData>> getInstructionTimes(String flightId) {
    return (select(instructionTimesTable)..where((t) => t.flightId.equals(flightId))).get();
  }

  /// Gets landings for a flight.
  Future<LandingsTableData?> getLandings(String flightId) {
    return (select(landingsTable)..where((t) => t.flightId.equals(flightId)))
        .getSingleOrNull();
  }

  /// Inserts a flight along with all related sub-entries in a transaction.
  Future<void> insertCompleteFlight({
    required FlightsTableCompanion flight,
    required List<FlightTimesTableCompanion> flightTimes,
    InstrumentTimesTableCompanion? instrumentTime,
    List<InstructionTimesTableCompanion> instructionTimes = const [],
    LandingsTableCompanion? landings,
  }) {
    return transaction(() async {
      // Ensure foreign key constraint is satisfied if aircraftModelId is provided
      if (flight.aircraftModelId.present && flight.aircraftModelId.value != null) {
        final modelId = flight.aircraftModelId.value!.trim();
        if (modelId.isNotEmpty) {
          final acClass = flightTimes.isNotEmpty ? flightTimes.first.aircraftClass.value : 0;
          await ensureAircraftModelExists(modelId: modelId, aircraftClass: acClass);
        }
      }

      await into(flightsTable).insert(flight);
      for (final ft in flightTimes) {
        await into(flightTimesTable).insert(ft);
      }
      if (instrumentTime != null) {
        await into(instrumentTimesTable).insert(instrumentTime);
      }
      for (final it in instructionTimes) {
        await into(instructionTimesTable).insert(it);
      }
      if (landings != null) {
        await into(landingsTable).insert(landings);
      }
    });
  }

  /// Deletes a flight (foreign keys with cascade handle sub-records).
  Future<int> deleteFlight(String flightId) {
    return (delete(flightsTable)..where((t) => t.id.equals(flightId))).go();
  }

  /// Deletes multiple flights in a single transaction.
  Future<int> deleteFlights(List<String> flightIds) {
    if (flightIds.isEmpty) return Future.value(0);
    return transaction(() async {
      int count = 0;
      for (final id in flightIds) {
        count += await deleteFlight(id);
      }
      return count;
    });
  }

  /// Aircraft Models helpers
  Future<List<AircraftModelsTableData>> getAllAircraftModels() {
    return select(aircraftModelsTable).get();
  }

  Stream<List<AircraftModelsTableData>> watchAllAircraftModels() {
    return select(aircraftModelsTable).watch();
  }

  Future<void> insertAircraftModel(AircraftModelsTableCompanion model) {
    return into(aircraftModelsTable).insert(model, mode: InsertMode.insertOrIgnore);
  }

  /// Ensures an aircraft model exists in SQLite database so foreign key never fails.
  Future<void> ensureAircraftModelExists({
    required String modelId,
    int aircraftClass = 0,
    int category = 0,
    String? manufacturer,
  }) async {
    await into(aircraftModelsTable).insert(
      AircraftModelsTableCompanion(
        id: Value(modelId),
        manufacturer: Value(manufacturer ?? 'SACAA'),
        model: Value(modelId),
        aircraftClass: Value(aircraftClass),
        category: Value(category),
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

