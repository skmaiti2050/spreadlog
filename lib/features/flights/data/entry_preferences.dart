import 'package:shared_preferences/shared_preferences.dart';

class EntryPreferences {
  static const _modeKey = 'flight_entry_duration_mode';
  static const modes = ['hhMm', 'decimal', 'hobbs'];
  const EntryPreferences();

  Future<String> loadDurationMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_modeKey);
    return modes.contains(value) ? value! : 'hhMm';
  }

  Future<void> saveDurationMode(String mode) async {
    if (!modes.contains(mode)) throw ArgumentError.value(mode, 'mode');
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_modeKey, mode)) {
      throw StateError('Could not remember the entry mode');
    }
  }
}
