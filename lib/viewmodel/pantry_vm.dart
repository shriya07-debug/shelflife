import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/enums.dart';
import '../repo/services.dart';

/// Encapsulates pantry list state, search, filter, and CRUD.
class PantryVM extends ChangeNotifier {
  String _filter = 'All';
  String _query = '';

  String get filter => _filter;
  String get query => _query;

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  // ---- Item lists ---------------------------------------------------------
  List<PantryItem> get all => Services.pantry.getAll();
  List<PantryItem> get active =>
      all.where((i) => i.status == ItemStatus.active).toList();
  List<PantryItem> get finished =>
      all.where((i) => i.status == ItemStatus.finished).toList();

  /// The list shown on the Pantry screen, after filter + search.
  List<PantryItem> get filtered {
    List<PantryItem> items;

    // Filter chip
    switch (_filter) {
      case 'All':
        items = active;
        break;
      case 'Favorites':
        items = active.where((i) => i.favorite).toList();
        break;
      case 'Finished':
        items = finished;
        break;
      default:
        items = active.where((i) => i.category == _filter).toList();
    }

    // Search
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q) ||
              (i.notes ?? '').toLowerCase().contains(q))
          .toList();
    }

    // Sort by expiry
    items.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return items;
  }

  /// Items expiring soonest (active only). Used by Home "Use First".
  List<PantryItem> get useFirst {
    final list = active;
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  int get totalActiveCount => active.length;
  int get expiringSoonCount =>
      active.where((i) => i.daysUntilExpiry <= 2).length;

  // ---- CRUD ---------------------------------------------------------------
  Future<void> add(PantryItem item) async {
    await Services.pantry.add(item);
    notifyListeners();
  }

  Future<void> update(PantryItem item) async {
    await Services.pantry.update(item);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await Services.pantry.delete(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(PantryItem item) async {
    await Services.pantry.update(item.copyWith(favorite: !item.favorite));
    notifyListeners();
  }

  Future<void> markFinished(PantryItem item) async {
    await Services.pantry
        .update(item.copyWith(status: ItemStatus.finished));
    notifyListeners();
  }

  Future<void> markActive(PantryItem item) async {
    await Services.pantry
        .update(item.copyWith(status: ItemStatus.active));
    notifyListeners();
  }

  /// Increase quantity on existing duplicate (used by add-item duplicate
  /// warning dialog).
  Future<void> bumpQuantity(PantryItem existing, double amount) async {
    final updated = existing.copyWith(quantity: existing.quantity + amount);
    await Services.pantry.update(updated);
    notifyListeners();
  }

  /// Find an existing active item with the same name (case-insensitive).
  PantryItem? findDuplicate(String name) {
    final n = name.trim().toLowerCase();
    for (final i in active) {
      if (i.name.trim().toLowerCase() == n) return i;
    }
    return null;
  }
}

/// Singleton — keep one instance app-wide.
final pantryVM = PantryVM();
