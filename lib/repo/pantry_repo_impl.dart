import 'package:hive_flutter/hive_flutter.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';
import 'seed_data.dart';

/// Hive-backed implementation of PantryRepo.
class PantryRepoImpl implements PantryRepo {
  static const _boxName = 'pantry';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<PantryItem> getAll() {
    return _box.values
        .map((v) => PantryItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  @override
  PantryItem? getById(String id) {
    final v = _box.get(id);
    if (v == null) return null;
    return PantryItem.fromMap(Map<String, dynamic>.from(v as Map));
  }

  @override
  Future<void> add(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> update(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  /// Seed-only helper used during first-launch only.
  Future<void> seedFromDefaults() async {
    for (final m in SeedData.pantry) {
      await _box.put(m['id'], m);
    }
  }
}
