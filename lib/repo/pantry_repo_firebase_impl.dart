import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';
import 'seed_data.dart';

/// Firestore-backed PantryRepo, scoped to users/{uid}/pantry.
/// Keeps an in-memory cache so the synchronous read API is preserved.
class PantryRepoFirebaseImpl implements PantryRepo {
  PantryRepoFirebaseImpl(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('pantry');

  final Map<String, Map<String, dynamic>> _cache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Increments on every cache change (local write or remote snapshot).
  /// ViewModels can listen to this in Piece 5 for live updates.
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
      onError: (_) {}, // e.g. permission-denied during logout/delete — ignore
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    revisions.dispose();
  }

  @override
  List<PantryItem> getAll() => _cache.values
      .map((m) => PantryItem.fromMap(Map<String, dynamic>.from(m)))
      .toList();

  @override
  PantryItem? getById(String id) {
    final m = _cache[id];
    return m == null
        ? null
        : PantryItem.fromMap(Map<String, dynamic>.from(m));
  }

  @override
  Future<void> add(PantryItem item) async {
    final m = item.toMap();
    _cache[item.id] = m; // optimistic
    _tick();
    await _col.doc(item.id).set(m);
  }

  @override
  Future<void> update(PantryItem item) => add(item);

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
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.delete(_col.doc(id));
    }
    await batch.commit();
  }

  /// First-login seed. Mirrors the Hive impl using the same SeedData.
  Future<void> seedFromDefaults() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in SeedData.pantry) {
      final m = Map<String, dynamic>.from(entry);
      _cache[m['id'] as String] = m;
      batch.set(_col.doc(m['id'] as String), m);
    }
    _tick();
    await batch.commit();
  }
}
