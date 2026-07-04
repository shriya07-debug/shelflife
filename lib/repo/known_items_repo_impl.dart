import 'package:hive_flutter/hive_flutter.dart';
import '../model/known_item.dart';
import 'known_items_repo.dart';
import 'seed_data.dart';

class KnownItemsRepoImpl implements KnownItemsRepo {
  // Device-local: shared across users on this device.
  static const _boxName = 'known_items';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<KnownItem> getAll() => _box.values
      .map((v) => KnownItem.fromMap(Map<String, dynamic>.from(v as Map)))
      .toList();

  @override
  List<KnownItem> search(String query, {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = getAll()
        .where((k) => k.nameLower.contains(q))
        .toList();
    // Prioritize: startsWith first, then contains; then by lastSeen desc
    results.sort((a, b) {
      final aStarts = a.nameLower.startsWith(q);
      final bStarts = b.nameLower.startsWith(q);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return b.lastSeen.compareTo(a.lastSeen);
    });
    return results.take(limit).toList();
  }

  @override
  Future<void> upsert(KnownItem item) async {
    await _box.put(item.nameLower, item.toMap());
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final m in SeedData.knownItems) {
      await _box.put(m['nameLower'], m);
    }
  }
}
