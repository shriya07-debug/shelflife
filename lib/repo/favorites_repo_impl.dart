import 'package:hive_flutter/hive_flutter.dart';
import 'favorites_repo.dart';
import 'seed_data.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  static const _boxName = 'favorites';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Set<String> getAll() => _box.keys.map((k) => k.toString()).toSet();

  @override
  bool isFavorite(String recipeId) => _box.get(recipeId) == true;

  @override
  Future<void> toggle(String recipeId) async {
    if (isFavorite(recipeId)) {
      await _box.delete(recipeId);
    } else {
      await _box.put(recipeId, true);
    }
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final id in SeedData.favoriteRecipeIds) {
      await _box.put(id, true);
    }
  }
}
