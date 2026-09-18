import 'package:drift/drift.dart';

class AircraftModelsTable extends Table {
  TextColumn get id => text()();
  TextColumn get manufacturer => text()();
  TextColumn get model => text()();
  IntColumn get aircraftClass => integer()();
  IntColumn get category => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

