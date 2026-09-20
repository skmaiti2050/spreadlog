import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/aircraft_models_table.dart';
import '../tables/model_endorsements_table.dart';

part 'aircraft_dao.g.dart';

@DriftAccessor(tables: [
  AircraftModelsTable,
  ModelEndorsementsTable,
])
class AircraftDao extends DatabaseAccessor<AppDatabase> with _$AircraftDaoMixin {
  AircraftDao(super.db);

  /// Default popular aircraft models to pre-seed if table is empty
  static final defaultModels = [
    AircraftModelsTableCompanion.insert(
      id: 'C172',
      manufacturer: 'Cessna',
      model: '172 Skyhawk',
      aircraftClass: 0, // SE
      category: 0, // Aeroplane
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'PA28',
      manufacturer: 'Piper',
      model: 'PA-28 Cherokee',
      aircraftClass: 0, // SE
      category: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'C182',
      manufacturer: 'Cessna',
      model: '182 Skylane',
      aircraftClass: 0, // SE
      category: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'BE76',
      manufacturer: 'Beechcraft',
      model: '76 Duchess',
      aircraftClass: 1, // ME
      category: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'PA34',
      manufacturer: 'Piper',
      model: 'PA-34 Seneca',
      aircraftClass: 1, // ME
      category: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'DA42',
      manufacturer: 'Diamond',
      model: 'DA42 Twin Star',
      aircraftClass: 1, // ME
      category: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AircraftModelsTableCompanion.insert(
      id: 'FNPT II',
      manufacturer: 'FSTD / Simulator',
      model: 'FNPT II Flight Trainer',
      aircraftClass: 0, // SE / FSTD
      category: 2, // FSTD
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  Future<void> seedDefaultModelsIfEmpty() async {
    final count = await select(aircraftModelsTable).get();
    if (count.isEmpty) {
      await batch((b) {
        b.insertAll(aircraftModelsTable, defaultModels);
      });
    }
  }

  Future<List<AircraftModelsTableData>> getAllModels() async {
    await seedDefaultModelsIfEmpty();
    return (select(aircraftModelsTable)..orderBy([(t) => OrderingTerm.asc(t.model)])).get();
  }

  Stream<List<AircraftModelsTableData>> watchAllModels() {
    return (select(aircraftModelsTable)..orderBy([(t) => OrderingTerm.asc(t.model)])).watch();
  }

  Future<AircraftModelsTableData?> getModelById(String id) {
    return (select(aircraftModelsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertOrUpdateModel(AircraftModelsTableCompanion model) {
    return into(aircraftModelsTable).insertOnConflictUpdate(model);
  }

  Future<int> deleteModel(String id) {
    return (delete(aircraftModelsTable)..where((t) => t.id.equals(id))).go();
  }

  // Model Endorsements
  Future<List<ModelEndorsementsTableData>> getAllEndorsements() {
    return (select(modelEndorsementsTable)..orderBy([(t) => OrderingTerm.desc(t.pilotDate)])).get();
  }

  Stream<List<ModelEndorsementsTableData>> watchAllEndorsements() {
    return (select(modelEndorsementsTable)..orderBy([(t) => OrderingTerm.desc(t.pilotDate)])).watch();
  }

  Future<ModelEndorsementsTableData?> getEndorsementByModelId(String modelId) {
    return (select(modelEndorsementsTable)..where((t) => t.aircraftModelId.equals(modelId))).getSingleOrNull();
  }

  Future<void> insertOrUpdateEndorsement(ModelEndorsementsTableCompanion endorsement) {
    return into(modelEndorsementsTable).insertOnConflictUpdate(endorsement);
  }

  Future<int> deleteEndorsement(String id) {
    return (delete(modelEndorsementsTable)..where((t) => t.id.equals(id))).go();
  }
}

