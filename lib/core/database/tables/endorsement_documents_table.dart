import 'package:drift/drift.dart';

/// Drift table storing scanned legal endorsements, ratings, and logbook certification documents.
class EndorsementDocumentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  DateTimeColumn get endorsementDate => dateTime()();
  IntColumn get pageNumber => integer().nullable()();
  TextColumn get originalPath => text()();
  TextColumn get processedPath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get sha256 => text()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get supersededBy => text().nullable()();
  TextColumn get supersedes => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

