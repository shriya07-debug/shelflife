import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import 'pantry_repo_impl.dart';
import 'shopping_repo_impl.dart';
import 'favorites_repo_impl.dart';
import 'services.dart';

/// Handles two flows:
/// 1. First login (Hive → Firestore): user was using app as guest, now signs up.
///    Guest data uploaded to Firestore.
/// 2. Later logins (Firestore → Hive): user signs in on new device or after
///    reinstall. Firestore is source of truth, download to Hive cache.
class SyncService {
  final _fs = FirebaseFirestore.instance;

  /// Upload local (guest) Hive data to Firestore. Used on first signup.
  Future<void> uploadGuestToCloud(String uid) async {
    final guestPantry = PantryRepoImpl(uid: null);
    final guestShopping = ShoppingRepoImpl(uid: null);
    final guestFavorites = FavoritesRepoImpl(uid: null);
    await Future.wait([
      guestPantry.init(),
      guestShopping.init(),
      guestFavorites.init(),
    ]);

    // Pantry
    for (final item in guestPantry.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.pantryCol)
          .doc(item.id)
          .set(item.toMap());
    }
    // Shopping
    for (final item in guestShopping.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.shoppingCol)
          .doc(item.id)
          .set(item.toMap());
    }
    // Favorites
    for (final rid in guestFavorites.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.favoritesCol)
          .doc(rid)
          .set({'favorite': true});
    }

    // Copy guest data into the user's Hive namespace (so we have a warm cache)
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);
    for (final item in guestPantry.getAll()) {
      await userPantry.add(item);
    }
    for (final item in guestShopping.getAll()) {
      await userShopping.add(item);
    }
    for (final rid in guestFavorites.getAll()) {
      await userFavorites.toggle(rid);
    }
    // Clear guest data now that it's migrated
    await guestPantry.clear();
    await guestShopping.clear();
    await guestFavorites.clear();
  }

  /// Download Firestore data into the user's Hive cache.
  /// Called on login, before repos are rebound.
  Future<void> downloadCloudToLocal(String uid) async {
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);

    // Pantry
    final pantrySnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.pantryCol)
        .get();
    if (pantrySnap.docs.isNotEmpty) {
      await userPantry.clear();
      for (final d in pantrySnap.docs) {
        await userPantry.addRaw(Map<String, dynamic>.from(d.data()));
      }
    }

    // Shopping
    final shopSnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.shoppingCol)
        .get();
    if (shopSnap.docs.isNotEmpty) {
      await userShopping.clear();
      for (final d in shopSnap.docs) {
        await userShopping.addRaw(Map<String, dynamic>.from(d.data()));
      }
    }

    // Favorites
    final favSnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.favoritesCol)
        .get();
    if (favSnap.docs.isNotEmpty) {
      final ids = favSnap.docs.map((d) => d.id).toSet();
      await userFavorites.setAll(ids);
    }
  }

  /// Called after signup: check whether the user's cloud is empty; if so,
  /// upload local guest data. Otherwise, download cloud to local.
  Future<void> onLogin(String uid, {required bool wasSignUp}) async {
    if (wasSignUp) {
      await uploadGuestToCloud(uid);
    } else {
      await downloadCloudToLocal(uid);
    }
    await Services.bindUserRepos(uid);
  }

  /// Called on logout: clear guest cache, don't touch user data.
  Future<void> onLogout() async {
    await Services.bindUserRepos(null);
  }

  /// Called on delete account: wipe Firestore + user's Hive namespace.
  Future<void> deleteAllUserData(String uid) async {
    // Firestore
    for (final col in [
      AppStrings.pantryCol,
      AppStrings.shoppingCol,
      AppStrings.favoritesCol,
    ]) {
      final snap = await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(col)
          .get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    }
    // Profile
    await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.meta)
        .doc(AppStrings.profileDoc)
        .delete();

    // Hive
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);
    await userPantry.clear();
    await userShopping.clear();
    await userFavorites.clear();
  }
}

final syncService = SyncService();
