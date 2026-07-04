import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import 'favorites_repo.dart';

class FavoritesRepoFirebaseImpl implements FavoritesRepo {
  final String uid;
  final FavoritesRepo cache;
  FavoritesRepoFirebaseImpl({required this.uid, required this.cache});
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.favoritesCol);

  @override
  Future<void> init() async => cache.init();

  @override
  Set<String> getAll() => cache.getAll();

  @override
  bool isFavorite(String recipeId) => cache.isFavorite(recipeId);

  @override
  Future<void> toggle(String recipeId) async {
    final was = cache.isFavorite(recipeId);
    await cache.toggle(recipeId);
    if (was) {
      await _col.doc(recipeId).delete();
    } else {
      await _col.doc(recipeId).set({'favorite': true});
    }
  }

  @override
  Future<void> setAll(Set<String> ids) async {
    await cache.setAll(ids);
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
    for (final id in ids) {
      await _col.doc(id).set({'favorite': true});
    }
  }

  @override
  Future<void> clear() async {
    await cache.clear();
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
