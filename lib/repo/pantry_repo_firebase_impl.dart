import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';

/// Firestore-backed pantry repo (per-user).
/// Uses Firestore's built-in offline persistence to work offline too.
/// Reads still come from a synced in-memory cache populated by SyncService.
class PantryRepoFirebaseImpl implements PantryRepo {
  final String uid;
  final PantryRepo cache; // Hive-backed local cache
  PantryRepoFirebaseImpl({required this.uid, required this.cache});

  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.pantryCol);

  @override
  Future<void> init() async => cache.init();

  @override
  List<PantryItem> getAll() => cache.getAll();

  @override
  PantryItem? getById(String id) => cache.getById(id);

  @override
  Future<void> add(PantryItem item) async {
    await cache.add(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    await cache.addRaw(map);
    await _col.doc(map['id'] as String).set(map);
  }

  @override
  Future<void> update(PantryItem item) async {
    await cache.update(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await cache.delete(id);
    await _col.doc(id).delete();
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
