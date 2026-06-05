import '../model/shopping_item.dart';

abstract class ShoppingRepo {
  Future<void> init();
  List<ShoppingItem> getAll();
  Future<void> add(ShoppingItem item);
  Future<void> update(ShoppingItem item);
  Future<void> delete(String id);
  Future<void> clear();
}
