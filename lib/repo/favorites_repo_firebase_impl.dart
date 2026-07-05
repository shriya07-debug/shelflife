import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'favorites_repo.dart';
import 'seed_data.dart';

/// Firestore-backed FavoritesRepo, scoped to users/{uid}/favorites.
/// Each favorited recipe is a doc whose id is the recipeId.
class FavoritesRepoFirebaseImpl implements FavoritesRepo {
  FavoritesRepoFirebaseImpl(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('favorites');

  final Set<String> _ids = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final ValueNotifier<int> revisions = ValueNotifier<int>(0);
  void _tick() => revisions.value++;

  @override
  Future<void> init() async {
    final snap = await _col.get();
    _ids
      ..clear()
      ..addAll(snap.docs.map((d) => d.id));
    _sub = _col.snapshots().listen(
      (snap) {
        _ids
          ..clear()
          ..addAll(snap.docs.map((d) => d.id));
        _tick();
      },
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    revisions.dispose();
  }

  @override
  Set<String> getAll() => Set<String>.from(_ids);

  @override
  bool isFavorite(String recipeId) => _ids.contains(recipeId);

  @override
  Future<void> toggle(String recipeId) async {
    if (_ids.contains(recipeId)) {
      _ids.remove(recipeId);
      _tick();
      await _col.doc(recipeId).delete();
    } else {
      _ids.add(recipeId);
      _tick();
      await _col.doc(recipeId).set({'fav': true});
    }
  }

  @override
  Future<void> clear() async {
    final ids = _ids.toList();
    _ids.clear();
    _tick();
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.delete(_col.doc(id));
    }
    await batch.commit();
  }

  Future<void> seedFromDefaults() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in SeedData.favoriteRecipeIds) {
      _ids.add(id);
      batch.set(_col.doc(id), {'fav': true});
    }
    _tick();
    await batch.commit();
  }
}
