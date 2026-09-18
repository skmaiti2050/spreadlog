import 'package:drift/drift.dart';

import 'flights_table.dart';

class FlightTimesTable extends Table {
  TextColumn get id => text()();
  TextColumn get flightId =>
      text().references(FlightsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get aircraftClass => integer()();
  IntColumn get period => integer()();
  IntColumn get role => integer()();
  IntColumn get durationMinutes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

