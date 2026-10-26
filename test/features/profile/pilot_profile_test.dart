import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/profile/domain/pilot_profile.dart';

void main() {
  group('PilotProfile Domain Tests', () {
    test('Default profile has no invented pilot details', () {
      const profile = PilotProfile.defaultProfile;
      expect(profile.pilotName, isEmpty);
      expect(profile.licenceNumber, isEmpty);
      expect(profile.regulatorId, 'sacaa');
      expect(profile.defaultPicName, 'SELF');
      expect(profile.isComplete, isFalse);
    });

    test('isComplete requires both name and licence', () {
      const named = PilotProfile(pilotName: 'J. DOE');
      expect(named.isComplete, isFalse);
      expect(
        named.copyWith(licenceNumber: '0270000000').isComplete,
        isTrue,
      );
    });

    test('copyWith updates specified fields correctly', () {
      const profile = PilotProfile.defaultProfile;
      final updated = profile.copyWith(
        pilotName: 'CAPT S. MAITI',
        licenceNumber: 'ZA-998877',
      );

      expect(updated.pilotName, 'CAPT S. MAITI');
      expect(updated.licenceNumber, 'ZA-998877');
      expect(updated.regulatorId, 'sacaa');
      expect(updated.defaultPicName, 'SELF');
    });

    test('JSON serialization roundtrip preserves values', () {
      const original = PilotProfile(
        pilotName: 'JOHN DOE',
        licenceNumber: 'ZA-555444',
        regulatorId: 'sacaa',
        defaultPicName: 'J. DOE',
      );

      final json = original.toJson();
      final restored = PilotProfile.fromJson(json);

      expect(restored, equals(original));
      expect(restored.pilotName, 'JOHN DOE');
      expect(restored.licenceNumber, 'ZA-555444');
      expect(restored.defaultPicName, 'J. DOE');
    });
  });
}

