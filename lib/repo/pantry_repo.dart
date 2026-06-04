import '../model/pantry_item.dart';

/// Abstract contract for pantry persistence.
abstract class PantryRepo {
  Future<void> init();

  List<PantryItem> getAll();
  PantryItem? getById(String id);

  Future<void> add(PantryItem item);
  Future<void> update(PantryItem item);
  Future<void> delete(String id);

  Future<void> clear();
}
