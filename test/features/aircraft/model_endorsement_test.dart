import 'package:aviation_logbook/features/aircraft/domain/aircraft_model.dart';
import 'package:aviation_logbook/features/aircraft/domain/model_endorsement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AircraftModel Domain Tests', () {
    test('Initializes with correct properties and displayName', () {
      const model = AircraftModel(
        id: 'C172',
        manufacturer: 'Cessna',
        model: '172 Skyhawk',
        aircraftClass: AircraftClass.singleEngine,
        category: AircraftCategory.aeroplane,
      );

      expect(model.id, 'C172');
      expect(model.manufacturer, 'Cessna');
      expect(model.model, '172 Skyhawk');
      expect(model.displayName, 'Cessna 172 Skyhawk');
      expect(model.aircraftClass, AircraftClass.singleEngine);
      expect(model.category, AircraftCategory.aeroplane);
    });

    test('copyWith updates specified fields', () {
      const original = AircraftModel(
        id: 'BE76',
        manufacturer: 'Beechcraft',
        model: '76 Duchess',
        aircraftClass: AircraftClass.multiEngine,
        category: AircraftCategory.aeroplane,
      );

      final updated = original.copyWith(model: 'Duchess ME');
      expect(updated.id, 'BE76');
      expect(updated.model, 'Duchess ME');
      expect(updated.displayName, 'Beechcraft Duchess ME');
      expect(updated.aircraftClass, AircraftClass.multiEngine);
    });

    test('JSON serialization roundtrip preserves values', () {
      const model = AircraftModel(
        id: 'DA42',
        manufacturer: 'Diamond',
        model: 'DA42 Twin Star',
        aircraftClass: AircraftClass.multiEngine,
        category: AircraftCategory.aeroplane,
      );

      final json = model.toJson();
      final reconstructed = AircraftModel.fromJson(json);

      expect(reconstructed, equals(model));
      expect(reconstructed.id, 'DA42');
      expect(reconstructed.aircraftClass, AircraftClass.multiEngine);
    });
  });

  group('ModelEndorsement Domain Tests', () {
    test('Initializes with required fields and optional nulls', () {
      final now = DateTime(2026, 9, 20, 10, 0);
      final endorsement = ModelEndorsement(
        id: 'me_001',
        aircraftModelId: 'C172',
        pilotDate: now,
        createdAt: now,
      );

      expect(endorsement.id, 'me_001');
      expect(endorsement.aircraftModelId, 'C172');
      expect(endorsement.pilotDate, now);
      expect(endorsement.instructorDate, isNull);
      expect(endorsement.instructorName, isNull);
      expect(endorsement.instructorLicence, isNull);
      expect(endorsement.sourceDocumentId, isNull);
      expect(endorsement.notes, isNull);
    });

    test('copyWith updates fields cleanly', () {
      final now = DateTime(2026, 9, 20);
      final e = ModelEndorsement(
        id: 'me_002',
        aircraftModelId: 'BE76',
        pilotDate: now,
        createdAt: now,
      );

      final updated = e.copyWith(
        instructorName: 'Capt. Miller',
        instructorLicence: 'ZA-642918',
        sourceDocumentId: 'doc_vault_123',
      );

      expect(updated.id, 'me_002');
      expect(updated.instructorName, 'Capt. Miller');
      expect(updated.instructorLicence, 'ZA-642918');
      expect(updated.sourceDocumentId, 'doc_vault_123');
      expect(updated.pilotDate, now);
    });

    test('JSON serialization roundtrip preserves all attributes', () {
      final pilotDate = DateTime(2026, 5, 10);
      final instructorDate = DateTime(2026, 5, 12);
      final createdAt = DateTime(2026, 5, 12, 14, 30);

      final endorsement = ModelEndorsement(
        id: 'me_003',
        aircraftModelId: 'DA42',
        pilotDate: pilotDate,
        instructorDate: instructorDate,
        instructorName: 'Capt. A. Smith',
        instructorLicence: 'ZA-999888',
        sourceDocumentId: 'doc_vault_999',
        notes: 'Glass cockpit differences training completed.',
        createdAt: createdAt,
      );

      final json = endorsement.toJson();
      final roundtrip = ModelEndorsement.fromJson(json);

      expect(roundtrip, equals(endorsement));
      expect(roundtrip.instructorName, 'Capt. A. Smith');
      expect(roundtrip.sourceDocumentId, 'doc_vault_999');
      expect(roundtrip.notes, 'Glass cockpit differences training completed.');
    });
  });
}
