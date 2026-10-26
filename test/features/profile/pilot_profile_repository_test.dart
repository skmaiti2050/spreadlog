import 'package:aviation_logbook/features/profile/data/pilot_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repo = PilotProfileRepository();

  test('fresh install has an incomplete, empty profile', () async {
    SharedPreferences.setMockInitialValues({});

    final profile = await repo.getProfile();

    expect(profile.pilotName, isEmpty);
    expect(profile.licenceNumber, isEmpty);
    expect(profile.isComplete, isFalse);
  });

  test('placeholders stored by earlier builds read back as empty', () async {
    SharedPreferences.setMockInitialValues({
      'pilot_profile_name': 'PILOT IN COMMAND',
      'pilot_profile_licence': 'ZA-123456',
    });

    final profile = await repo.getProfile();

    expect(profile.pilotName, isEmpty);
    expect(profile.licenceNumber, isEmpty);
  });

  test('real details round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = (await repo.getProfile()).copyWith(
      pilotName: 'J. DOE',
      licenceNumber: '0270000000',
    );

    await repo.saveProfile(saved);

    expect(await repo.getProfile(), saved);
  });
}
