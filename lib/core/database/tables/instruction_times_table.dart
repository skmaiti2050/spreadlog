import 'package:drift/drift.dart';

import 'flights_table.dart';

class InstructionTimesTable extends Table {
  TextColumn get id => text()();
  TextColumn get flightId =>
      text().references(FlightsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get category => integer()();
  IntColumn get durationMinutes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

