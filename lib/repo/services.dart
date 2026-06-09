import 'package:hive_flutter/hive_flutter.dart';
import 'pantry_repo.dart';
import 'pantry_repo_impl.dart';
import 'shopping_repo.dart';
import 'shopping_repo_impl.dart';
import 'favorites_repo.dart';
import 'favorites_repo_impl.dart';
import 'settings_repo.dart';
import 'settings_repo_impl.dart';
import 'recipe_repo.dart';
import 'recipe_repo_impl.dart';

/// Tiny service locator. Call Services.init() once from main().
/// All ViewModels read repos from here.
class Services {
  Services._();

  static late final PantryRepo pantry;
  static late final ShoppingRepo shopping;
  static late final FavoritesRepo favorites;
  static late final SettingsRepo settings;
  static late final RecipeRepo recipes;

  static Future<void> init() async {
    await Hive.initFlutter();
    final p = PantryRepoImpl();
    final s = ShoppingRepoImpl();
    final f = FavoritesRepoImpl();
    final set = SettingsRepoImpl();
    await Future.wait([p.init(), s.init(), f.init(), set.init()]);

    pantry = p;
    shopping = s;
    favorites = f;
    settings = set;
    recipes = RecipeRepoImpl();

    // First-launch seeding
    if (!settings.seeded) {
      await p.seedFromDefaults();
      await s.seedFromDefaults();
      await f.seedFromDefaults();
      await settings.markSeeded();
    }
  }

  /// Wipe all data + re-seed. Used by the "Reset Demo Data" button.
  static Future<void> resetAndReseed() async {
    await pantry.clear();
    await shopping.clear();
    await favorites.clear();
    await settings.clearSeeded();
    final p = pantry as PantryRepoImpl;
    final s = shopping as ShoppingRepoImpl;
    final f = favorites as FavoritesRepoImpl;
    await p.seedFromDefaults();
    await s.seedFromDefaults();
    await f.seedFromDefaults();
    await settings.markSeeded();
  }
}
