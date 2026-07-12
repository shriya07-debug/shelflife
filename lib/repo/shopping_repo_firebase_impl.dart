import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';
import 'seed_data.dart';

/// Firestore-backed ShoppingRepo, scoped to users/{uid}/shopping.
class ShoppingRepoFirebaseImpl implements ShoppingRepo {
  ShoppingRepoFirebaseImpl(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(uid).collection('shopping');

  final Map<String, Map<String, dynamic>> _cache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final ValueNotifier<int> revisions = ValueNotifier<int>(0);
  void _tick() => revisions.value++;

  void _hydrate(QuerySnapshot<Map<String, dynamic>> snap) {
    _cache
      ..clear()
      ..addEntries(snap.docs.map((d) => MapEntry(d.id, d.data())));
  }

  @override
  Future<void> init() async {
    _hydrate(await _col.get());
    _sub = _col.snapshots().listen(
      (snap) {
        _hydrate(snap);
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
  List<ShoppingItem> getAll() => _cache.values
      .map((m) => ShoppingItem.fromMap(Map<String, dynamic>.from(m)))
      .toList();

  @override
  Future<void> add(ShoppingItem item) async {
    final m = item.toMap();
    _cache[item.id] = m;
    _tick();
    await _col.doc(item.id).set(m);
  }

  @override
  Future<void> update(ShoppingItem item) => add(item);

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
    _tick();
    await _col.doc(id).delete();
  }

  @override
  Future<void> clear() async {
    final ids = _cache.keys.toList();
    _cache.clear();
    _tick();
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_col.doc(id));
    }
    await batch.commit();
  }

  Future<void> seedFromDefaults() async {
    final batch = _firestore.batch();
    for (final entry in SeedData.shopping) {
      final m = Map<String, dynamic>.from(entry);
      _cache[m['id'] as String] = m;
      batch.set(_col.doc(m['id'] as String), m);
    }
    _tick();
    await batch.commit();
  }
}
