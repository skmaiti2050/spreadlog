import 'package:drift/drift.dart';

import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/aircraft_dao.dart';
import '../domain/aircraft_model.dart';
import '../domain/aircraft_repository.dart';
import '../domain/model_endorsement.dart';

class DriftAircraftRepository implements AircraftRepository {
  final AircraftDao _dao;

  DriftAircraftRepository(this._dao);

  @override
  Stream<List<AircraftModel>> watchAllModels() {
    return _dao.watchAllModels().map(
      (list) => list.map(_mapModelDataToDomain).toList(),
    );
  }

  @override
  Future<List<AircraftModel>> getAllModels() async {
    final list = await _dao.getAllModels();
    return list.map(_mapModelDataToDomain).toList();
  }

  @override
  Future<AircraftModel?> getModelById(String id) async {
    final data = await _dao.getModelById(id);
    return data != null ? _mapModelDataToDomain(data) : null;
  }

  @override
  Future<void> saveModel(AircraftModel model) async {
    await _dao.insertOrUpdateModel(
      AircraftModelsTableCompanion.insert(
        id: model.id,
        manufacturer: model.manufacturer,
        model: model.model,
        aircraftClass: model.aircraftClass.index,
        category: model.category.index,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteModel(String id) async {
    await _dao.deleteModel(id);
  }

  @override
  Stream<List<ModelEndorsement>> watchAllEndorsements() {
    return _dao.watchAllEndorsements().map(
      (list) => list.map(_mapEndorsementDataToDomain).toList(),
    );
  }

  @override
  Future<List<ModelEndorsement>> getAllEndorsements() async {
    final list = await _dao.getAllEndorsements();
    return list.map(_mapEndorsementDataToDomain).toList();
  }

  @override
  Future<ModelEndorsement?> getEndorsementByModelId(String modelId) async {
    final data = await _dao.getEndorsementByModelId(modelId);
    return data != null ? _mapEndorsementDataToDomain(data) : null;
  }

  @override
  Future<void> saveEndorsement(ModelEndorsement endorsement) async {
    await _dao.insertOrUpdateEndorsement(
      ModelEndorsementsTableCompanion.insert(
        id: endorsement.id,
        aircraftModelId: endorsement.aircraftModelId,
        pilotDate: endorsement.pilotDate,
        instructorDate: Value(endorsement.instructorDate),
        instructorName: Value(endorsement.instructorName),
        instructorLicence: Value(endorsement.instructorLicence),
        sourceDocumentId: Value(endorsement.sourceDocumentId),
        notes: Value(endorsement.notes),
        createdAt: endorsement.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteEndorsement(
    String id, {
    String reason = 'Record corrected',
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A correction reason is required');
    }
    await _dao.attachedDatabase.transaction(() async {
      final rows = await _dao.getAllEndorsements();
      final matching = rows.where((row) => row.id == id);
      if (matching.isEmpty) return;
      final row = matching.single;
      await _dao.attachedDatabase.customStatement(
        'INSERT INTO endorsement_corrections (endorsement_id, aircraft_model_id, removed_at, reason, snapshot) VALUES (?, ?, ?, ?, ?)',
        [
          id,
          row.aircraftModelId,
          DateTime.now().toUtc().toIso8601String(),
          reason.trim(),
          jsonEncode(row.toJson()),
        ],
      );
      await _dao.deleteEndorsement(id);
    });
  }

  AircraftModel _mapModelDataToDomain(AircraftModelsTableData d) {
    return AircraftModel(
      id: d.id,
      manufacturer: d.manufacturer,
      model: d.model,
      aircraftClass: d.aircraftClass < AircraftClass.values.length
          ? AircraftClass.values[d.aircraftClass]
          : AircraftClass.singleEngine,
      category: d.category < AircraftCategory.values.length
          ? AircraftCategory.values[d.category]
          : AircraftCategory.aeroplane,
    );
  }

  ModelEndorsement _mapEndorsementDataToDomain(ModelEndorsementsTableData d) {
    return ModelEndorsement(
      id: d.id,
      aircraftModelId: d.aircraftModelId,
      pilotDate: d.pilotDate,
      instructorDate: d.instructorDate,
      instructorName: d.instructorName,
      instructorLicence: d.instructorLicence,
      sourceDocumentId: d.sourceDocumentId,
      notes: d.notes,
      createdAt: d.createdAt,
    );
  }
}
