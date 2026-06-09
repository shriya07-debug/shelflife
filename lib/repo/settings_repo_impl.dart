import 'package:hive_flutter/hive_flutter.dart';
import 'settings_repo.dart';

class SettingsRepoImpl implements SettingsRepo {
  static const _boxName = 'settings';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  bool get darkMode => _box.get('darkMode', defaultValue: false) as bool;

  @override
  Future<void> setDarkMode(bool v) async => _box.put('darkMode', v);

  @override
  bool get seeded => _box.get('seeded', defaultValue: false) as bool;

  @override
  Future<void> markSeeded() async => _box.put('seeded', true);

  @override
  Future<void> clearSeeded() async => _box.delete('seeded');
}
