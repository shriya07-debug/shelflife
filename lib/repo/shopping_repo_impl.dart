import 'package:hive_flutter/hive_flutter.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';
import 'seed_data.dart';

class ShoppingRepoImpl implements ShoppingRepo {
  static const _boxName = 'shopping';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<ShoppingItem> getAll() {
    return _box.values
        .map((v) => ShoppingItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  @override
  Future<void> add(ShoppingItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> update(ShoppingItem item) async {
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

  Future<void> seedFromDefaults() async {
    for (final m in SeedData.shopping) {
      await _box.put(m['id'], m);
    }
  }
}
