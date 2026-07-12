import 'package:shared_preferences/shared_preferences.dart';
import 'settings_repo.dart';

/// Device-level settings backed by shared_preferences (available before login).
class SettingsRepoImpl implements SettingsRepo {
  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  bool get darkMode => _prefs.getBool('darkMode') ?? false;

  @override
  Future<void> setDarkMode(bool v) async => _prefs.setBool('darkMode', v);

  @override
  bool get seeded => _prefs.getBool('seeded') ?? false;

  @override
  Future<void> markSeeded() async => _prefs.setBool('seeded', true);

  @override
  Future<void> clearSeeded() async => _prefs.remove('seeded');
}
