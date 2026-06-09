import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/shopping_item.dart';
import '../repo/services.dart';
import 'pantry_vm.dart';

class ShoppingVM extends ChangeNotifier {
  List<ShoppingItem> get all => Services.shopping.getAll();
  int get checkedCount => all.where((i) => i.checked).length;

  Future<void> add(ShoppingItem item) async {
    await Services.shopping.add(item);
    notifyListeners();
  }

  Future<void> update(ShoppingItem item) async {
    await Services.shopping.update(item);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await Services.shopping.delete(id);
    notifyListeners();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    item.checked = !item.checked;
    await Services.shopping.update(item);
    notifyListeners();
  }

  /// Move all checked items to the pantry, then remove them from shopping.
  /// Returns number moved.
  Future<int> moveCheckedToPantry() async {
    final checked = all.where((i) => i.checked).toList();
    final now = DateTime.now();
    for (final s in checked) {
      final p = PantryItem(
        id: 'p_${now.microsecondsSinceEpoch}_${s.id}',
        name: s.name,
        category: 'Other',
        quantity: 1,
        unitCode: 'unit',
        expiryDate: now.add(const Duration(days: 7)),
        addedDate: now,
        purchaseDate: now,
      );
      await Services.pantry.add(p);
      await Services.shopping.delete(s.id);
    }
    pantryVM.notifyListeners();
    notifyListeners();
    return checked.length;
  }

  /// Add a single missing ingredient from a recipe to the shopping list.
  Future<void> addIngredient(String name, String? note) async {
    await add(ShoppingItem(
      id: 's_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      note: note,
    ));
  }
}

final shoppingVM = ShoppingVM();
