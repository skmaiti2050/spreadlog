import 'package:aviation_logbook/core/database/app_database.dart';
import 'package:aviation_logbook/features/aircraft/data/drift_aircraft_repository.dart';
import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/aircraft/domain/model_endorsement.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAircraftRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAircraftRepository(db.aircraftDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftAircraftRepository & AircraftDao Integration Tests', () {
    test('getAllModels automatically seeds default models when empty', () async {
      final models = await repository.getAllModels();

      expect(models, isNotEmpty);
      expect(models.any((m) => m.id == 'C172'), isTrue);
      expect(models.any((m) => m.id == 'BE76'), isTrue);
      expect(models.any((m) => m.id == 'DA42'), isTrue);
      expect(models.any((m) => m.id == 'FNPT II'), isTrue);
    });

    test('saveModel inserts new aircraft model and getModelById retrieves it', () async {
      const customModel = AircraftModel(
        id: 'SR22',
        manufacturer: 'Cirrus',
        model: 'SR22 G6',
        aircraftClass: AircraftClass.singleEngine,
        category: AircraftCategory.aeroplane,
      );

      await repository.saveModel(customModel);
      final retrieved = await repository.getModelById('SR22');

      expect(retrieved, isNotNull);
      expect(retrieved!.manufacturer, 'Cirrus');
      expect(retrieved.model, 'SR22 G6');
      expect(retrieved.displayName, 'Cirrus SR22 G6');
      expect(retrieved.aircraftClass, AircraftClass.singleEngine);
    });

    test('saveEndorsement persists pilot checkout, instructor sign-off, and notes', () async {
      await repository.getAllModels(); // ensure seed

      final now = DateTime(2026, 9, 20);
      final endorsement = ModelEndorsement(
        id: 'endorse_be76',
        aircraftModelId: 'BE76',
        pilotDate: now,
        instructorDate: now,
        instructorName: 'Capt. J. Miller',
        instructorLicence: 'ZA-642918',
        notes: 'BE76 Duchess Multi-Engine checkout completed with asymmetric handling.',
        createdAt: now,
      );

      await repository.saveEndorsement(endorsement);
      final retrieved = await repository.getEndorsementByModelId('BE76');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'endorse_be76');
      expect(retrieved.aircraftModelId, 'BE76');
      expect(retrieved.instructorName, 'Capt. J. Miller');
      expect(retrieved.instructorLicence, 'ZA-642918');
      expect(retrieved.notes, contains('Multi-Engine checkout'));
    });

    test('deleteEndorsement removes endorsement while keeping aircraft model intact', () async {
      await repository.getAllModels();

      final endorsement = ModelEndorsement(
        id: 'endorse_c172',
        aircraftModelId: 'C172',
        pilotDate: DateTime(2026, 1, 15),
        createdAt: DateTime(2026, 1, 15),
      );

      await repository.saveEndorsement(endorsement);
      expect(await repository.getEndorsementByModelId('C172'), isNotNull);

      await repository.deleteEndorsement('endorse_c172');
      expect(await repository.getEndorsementByModelId('C172'), isNull);

      final model = await repository.getModelById('C172');
      expect(model, isNotNull);
    });

    test('deleteModel cascades and removes associated endorsement', () async {
      const tempModel = AircraftModel(
        id: 'TEMP_MODEL',
        manufacturer: 'TestMaker',
        model: 'Test 100',
        aircraftClass: AircraftClass.singleEngine,
        category: AircraftCategory.aeroplane,
      );

      await repository.saveModel(tempModel);
      final endorsement = ModelEndorsement(
        id: 'endorse_temp',
        aircraftModelId: 'TEMP_MODEL',
        pilotDate: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1),
      );
      await repository.saveEndorsement(endorsement);

      expect(await repository.getModelById('TEMP_MODEL'), isNotNull);
      expect(await repository.getEndorsementByModelId('TEMP_MODEL'), isNotNull);

      await repository.deleteModel('TEMP_MODEL');
      expect(await repository.getModelById('TEMP_MODEL'), isNull);
      expect(await repository.getEndorsementByModelId('TEMP_MODEL'), isNull);
    });
  });
}
