import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/enums.dart';
import 'pantry_vm.dart';

/// Holds form state for the Add Item screen.
class AddItemVM extends ChangeNotifier {
  String name = '';
  double quantity = 1;
  String unitCode = 'unit';
  String category = 'Other';
  DateTime? expiry;
  DateTime? purchaseDate;
  StorageLocation storage = StorageLocation.fridge;

  void update({
    String? name,
    double? quantity,
    String? unitCode,
    String? category,
    DateTime? expiry,
    DateTime? purchaseDate,
    StorageLocation? storage,
  }) {
    if (name != null) this.name = name;
    if (quantity != null) this.quantity = quantity;
    if (unitCode != null) this.unitCode = unitCode;
    if (category != null) this.category = category;
    if (expiry != null) this.expiry = expiry;
    if (purchaseDate != null) this.purchaseDate = purchaseDate;
    if (storage != null) this.storage = storage;
    notifyListeners();
  }

  void clearExpiry() {
    expiry = null;
    notifyListeners();
  }

  void clearPurchase() {
    purchaseDate = null;
    notifyListeners();
  }

  /// "Apply suggestion" — if purchaseDate is set, suggested expiry is 3 days
  /// after purchase. Otherwise 3 days from now.
  void applySuggestion(int days) {
    final base = purchaseDate ?? DateTime.now();
    expiry = base.add(Duration(days: days));
    notifyListeners();
  }

  PantryItem? findDuplicate() => pantryVM.findDuplicate(name);

  PantryItem buildItem() {
    final now = DateTime.now();
    return PantryItem(
      id: 'p_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      category: category,
      quantity: quantity,
      unitCode: unitCode,
      expiryDate: expiry ?? now.add(const Duration(days: 7)),
      addedDate: now,
      purchaseDate: purchaseDate ?? now,
      storage: storage,
    );
  }

  void reset() {
    name = '';
    quantity = 1;
    unitCode = 'unit';
    category = 'Other';
    expiry = null;
    purchaseDate = null;
    storage = StorageLocation.fridge;
    notifyListeners();
  }
}

final addItemVM = AddItemVM();
