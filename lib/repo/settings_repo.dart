abstract class SettingsRepo {
  Future<void> init();
  bool get darkMode;
  Future<void> setDarkMode(bool v);
  bool get seeded;
  Future<void> markSeeded();
  Future<void> clearSeeded();
}
