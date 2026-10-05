import 'package:drift/drift.dart';

import 'connection/connection.dart' as conn;
import 'daos/aircraft_dao.dart';
import 'daos/endorsements_dao.dart';
import 'daos/flights_dao.dart';
import 'tables/aircraft_models_table.dart';
import 'tables/endorsement_documents_table.dart';
import 'tables/flight_times_table.dart';
import 'tables/flights_table.dart';
import 'tables/instruction_times_table.dart';
import 'tables/instrument_times_table.dart';
import 'tables/landings_table.dart';
import 'tables/model_endorsements_table.dart';

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
    ModelEndorsementsTable,
  ],
  daos: [FlightsDao, EndorsementsDao, AircraftDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? conn.openConnection());

  @override
  int get schemaVersion => 5;

  Future<void> _createCorrectionHistory() => customStatement('''
    CREATE TABLE IF NOT EXISTS endorsement_corrections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      endorsement_id TEXT NOT NULL,
      aircraft_model_id TEXT NOT NULL,
      removed_at TEXT NOT NULL,
      reason TEXT NOT NULL,
      snapshot TEXT NOT NULL
    )
  ''');

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createCorrectionHistory();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(endorsementDocumentsTable);
        }
        if (from < 3) {
          await m.createTable(modelEndorsementsTable);
        }
        if (from < 4) await _createCorrectionHistory();
        if (from >= 2 && from < 5) {
          await m.addColumn(
            endorsementDocumentsTable,
            endorsementDocumentsTable.pagesJson,
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
