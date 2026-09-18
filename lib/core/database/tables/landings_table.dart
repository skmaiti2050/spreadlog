import 'package:drift/drift.dart';

import 'flights_table.dart';

class LandingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get flightId => text()
      .unique()
      .references(FlightsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayCount => integer().withDefault(const Constant(0))();
  IntColumn get nightCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

