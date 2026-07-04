import '../model/known_item.dart';

abstract class KnownItemsRepo {
  Future<void> init();
  List<KnownItem> getAll();
  List<KnownItem> search(String query, {int limit = 5});
  Future<void> upsert(KnownItem item);
  Future<void> clear();
}
