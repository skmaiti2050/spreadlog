import 'package:drift/drift.dart';

import 'aircraft_models_table.dart';
import 'endorsement_documents_table.dart';

class ModelEndorsementsTable extends Table {
  TextColumn get id => text()();
  TextColumn get aircraftModelId =>
      text().references(AircraftModelsTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get pilotDate => dateTime()();
  DateTimeColumn get instructorDate => dateTime().nullable()();
  TextColumn get instructorName => text().nullable()();
  TextColumn get instructorLicence => text().nullable()();
  TextColumn get sourceDocumentId => text()
      .nullable()
      .references(EndorsementDocumentsTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

