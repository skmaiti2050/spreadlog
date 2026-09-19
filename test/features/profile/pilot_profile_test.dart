import 'package:flutter_test/flutter_test.dart';
import 'package:aviation_logbook/features/profile/domain/pilot_profile.dart';

void main() {
  group('PilotProfile Domain Tests', () {
    test('Default profile has sensible SACAA defaults', () {
      const profile = PilotProfile.defaultProfile;
      expect(profile.pilotName, 'PILOT IN COMMAND');
      expect(profile.licenceNumber, 'ZA-123456');
      expect(profile.regulatorId, 'sacaa');
      expect(profile.defaultPicName, 'SELF');
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

