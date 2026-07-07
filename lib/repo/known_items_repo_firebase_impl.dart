import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'known_items_repo.dart';

/// SHARED across all users: Firestore collection 'known_items'.
/// Doc id is the lower-cased name, so 'Milk' and 'milk' merge into one.
class KnownItemsRepoFirebaseImpl implements KnownItemsRepo {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('known_items');

  final Map<String, KnownItem> _cache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  String _key(String name) => name.trim().toLowerCase().replaceAll('/', '_');

  void _apply(QuerySnapshot<Map<String, dynamic>> snap) {
    _cache
      ..clear()
      ..addEntries(snap.docs.map((d) {
        final m = d.data();
        return MapEntry(
          d.id,
          KnownItem(
            name: (m['name'] as String?) ?? d.id,
            category: (m['category'] as String?) ?? 'Other',
          ),
        );
      }));
  }

  @override
  Future<void> init() async {
    _apply(await _col.get());
    _sub = _col.snapshots().listen(_apply, onError: (_) {});
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  List<KnownItem> getAll() => _cache.values.toList();

  @override
  Future<void> remember(String name, String category) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final key = _key(n);
    if (key.isEmpty) return;
    _cache[key] = KnownItem(name: n, category: category);
    await _col.doc(key).set({'name': n, 'category': category});
  }
}
