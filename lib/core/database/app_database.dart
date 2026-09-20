import 'package:drift/drift.dart';

import 'connection/connection.dart' as conn;
import 'daos/endorsements_dao.dart';
import 'daos/flights_dao.dart';
import 'tables/aircraft_models_table.dart';
import 'tables/endorsement_documents_table.dart';
import 'tables/flight_times_table.dart';
import 'tables/flights_table.dart';
import 'tables/instruction_times_table.dart';
import 'tables/instrument_times_table.dart';
import 'tables/landings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FlightsTable,
    FlightTimesTable,
    InstrumentTimesTable,
    InstructionTimesTable,
    LandingsTable,
    AircraftModelsTable,
    EndorsementDocumentsTable,
  ],
  daos: [
    FlightsDao,
    EndorsementsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? conn.openConnection());

  @override
  int get schemaVersion => 2;


  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(endorsementDocumentsTable);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

