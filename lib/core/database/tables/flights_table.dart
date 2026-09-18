import 'package:drift/drift.dart';

import 'aircraft_models_table.dart';

class FlightsTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get aircraftModelId =>
      text().nullable().references(AircraftModelsTable, #id)();
  TextColumn get registration => text()();
  TextColumn get picName => text()();
  TextColumn get remarks => text().withDefault(const Constant(''))();
  BoolColumn get soloCrossCountry =>
      boolean().withDefault(const Constant(false))();
  IntColumn get fstdActualMinutes =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

