import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pantry_repo.dart';
import 'pantry_repo_firebase_impl.dart';
import 'shopping_repo.dart';
import 'shopping_repo_firebase_impl.dart';
import 'favorites_repo.dart';
import 'favorites_repo_firebase_impl.dart';
import 'settings_repo.dart';
import 'settings_repo_impl.dart';
import 'recipe_repo.dart';
import 'recipe_repo_impl.dart';

/// Service locator.
///  • [settings] (device-level, Hive) and [recipes] (static) are ready after
///    [init], called once from main().
///  • [pantry] / [shopping] / [favorites] are per-user Firestore repos, bound
///    via [bindUser] after login and released via [unbindUser] on logout.
class Services {
  Services._();

  static late final SettingsRepo settings;
  static late final RecipeRepo recipes;

  static PantryRepoFirebaseImpl? _pantry;
  static ShoppingRepoFirebaseImpl? _shopping;
  static FavoritesRepoFirebaseImpl? _favorites;

  static PantryRepo get pantry => _pantry!;
  static ShoppingRepo get shopping => _shopping!;
  static FavoritesRepo get favorites => _favorites!;

  /// Firebase impls expose these for Piece 5 (live-sync VM subscriptions).
  static PantryRepoFirebaseImpl? get pantryImpl => _pantry;
  static ShoppingRepoFirebaseImpl? get shoppingImpl => _shopping;
  static FavoritesRepoFirebaseImpl? get favoritesImpl => _favorites;

  static bool get hasUser => _pantry != null;

  /// Startup: device settings + static recipes. No user data yet.
  static Future<void> init() async {
    await Hive.initFlutter();
    final set = SettingsRepoImpl();
    await set.init();
    settings = set;
    recipes = RecipeRepoImpl();
  }

  /// Bind + hydrate repos for [uid]. Seeds demo data on first login only.
  static Future<void> bindUser(String uid) async {
    if (_pantry != null) unbindUser();

    final p = PantryRepoFirebaseImpl(uid);
    final s = ShoppingRepoFirebaseImpl(uid);
    final f = FavoritesRepoFirebaseImpl(uid);
    await Future.wait([p.init(), s.init(), f.init()]);
    _pantry = p;
    _shopping = s;
    _favorites = f;

    final flags = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('flags');
    final snap = await flags.get();
    final seeded = (snap.data()?['seeded'] as bool?) ?? false;
    if (!seeded) {
      await p.seedFromDefaults();
      await s.seedFromDefaults();
      await f.seedFromDefaults();
      await flags.set({'seeded': true}, SetOptions(merge: true));
    }
  }

  static void unbindUser() {
    _pantry?.dispose();
    _shopping?.dispose();
    _favorites?.dispose();
    _pantry = null;
    _shopping = null;
    _favorites = null;
  }

  /// Reset the CURRENT user's cloud data back to demo defaults.
  static Future<void> resetAndReseed() async {
    final p = _pantry, s = _shopping, f = _favorites;
    if (p == null || s == null || f == null) return;
    await p.clear();
    await s.clear();
    await f.clear();
    await p.seedFromDefaults();
    await s.seedFromDefaults();
    await f.seedFromDefaults();
  }
}
