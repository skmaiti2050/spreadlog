import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pilot_profile.dart';

/// Repository for persisting pilot profile to local SharedPreferences.
class PilotProfileRepository {
  static const _keyPilotName = 'pilot_profile_name';
  static const _keyLicenceNumber = 'pilot_profile_licence';
  static const _keyRegulatorId = 'pilot_profile_regulator';
  static const _keyDefaultPicName = 'pilot_profile_default_pic';

  const PilotProfileRepository();

  Future<PilotProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyPilotName) ?? 'PILOT IN COMMAND';
    final licence = prefs.getString(_keyLicenceNumber) ?? 'ZA-123456';
    final regulator = prefs.getString(_keyRegulatorId) ?? 'sacaa';
    final defaultPic = prefs.getString(_keyDefaultPicName) ?? 'SELF';

    return PilotProfile(
      pilotName: name,
      licenceNumber: licence,
      regulatorId: regulator,
      defaultPicName: defaultPic,
    );
  }

  Future<void> saveProfile(PilotProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPilotName, profile.pilotName);
    await prefs.setString(_keyLicenceNumber, profile.licenceNumber);
    await prefs.setString(_keyRegulatorId, profile.regulatorId);
    await prefs.setString(_keyDefaultPicName, profile.defaultPicName);
  }
}

