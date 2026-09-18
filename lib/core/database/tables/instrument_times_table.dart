import 'package:drift/drift.dart';

import 'flights_table.dart';

class InstrumentTimesTable extends Table {
  TextColumn get id => text()();
  TextColumn get flightId => text()
      .unique()
      .references(FlightsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get navaids => text().nullable()();
  TextColumn get place => text().nullable()();
  IntColumn get actualMinutes => integer().withDefault(const Constant(0))();
  IntColumn get fstdMinutes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

