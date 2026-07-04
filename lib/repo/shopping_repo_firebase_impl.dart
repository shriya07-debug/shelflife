import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';

class ShoppingRepoFirebaseImpl implements ShoppingRepo {
  final String uid;
  final ShoppingRepo cache;
  ShoppingRepoFirebaseImpl({required this.uid, required this.cache});
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.shoppingCol);

  @override
  Future<void> init() async => cache.init();

  @override
  List<ShoppingItem> getAll() => cache.getAll();

  @override
  Future<void> add(ShoppingItem item) async {
    await cache.add(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    await cache.addRaw(map);
    await _col.doc(map['id'] as String).set(map);
  }

  @override
  Future<void> update(ShoppingItem item) async {
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
