// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flights_dao.dart';

// ignore_for_file: type=lint
mixin _$FlightsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AircraftModelsTableTable get aircraftModelsTable =>
      attachedDatabase.aircraftModelsTable;
  $FlightsTableTable get flightsTable => attachedDatabase.flightsTable;
  $FlightTimesTableTable get flightTimesTable =>
      attachedDatabase.flightTimesTable;
  $InstrumentTimesTableTable get instrumentTimesTable =>
      attachedDatabase.instrumentTimesTable;
  $InstructionTimesTableTable get instructionTimesTable =>
      attachedDatabase.instructionTimesTable;
  $LandingsTableTable get landingsTable => attachedDatabase.landingsTable;
  FlightsDaoManager get managers => FlightsDaoManager(this);
}

class FlightsDaoManager {
  final _$FlightsDaoMixin _db;
  FlightsDaoManager(this._db);
  $$AircraftModelsTableTableTableManager get aircraftModelsTable =>
      $$AircraftModelsTableTableTableManager(
        _db.attachedDatabase,
        _db.aircraftModelsTable,
      );
  $$FlightsTableTableTableManager get flightsTable =>
      $$FlightsTableTableTableManager(_db.attachedDatabase, _db.flightsTable);
  $$FlightTimesTableTableTableManager get flightTimesTable =>
      $$FlightTimesTableTableTableManager(
        _db.attachedDatabase,
        _db.flightTimesTable,
      );
  $$InstrumentTimesTableTableTableManager get instrumentTimesTable =>
      $$InstrumentTimesTableTableTableManager(
        _db.attachedDatabase,
        _db.instrumentTimesTable,
      );
  $$InstructionTimesTableTableTableManager get instructionTimesTable =>
      $$InstructionTimesTableTableTableManager(
        _db.attachedDatabase,
        _db.instructionTimesTable,
      );
  $$LandingsTableTableTableManager get landingsTable =>
      $$LandingsTableTableTableManager(_db.attachedDatabase, _db.landingsTable);
}
