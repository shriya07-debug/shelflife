import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../repo/services.dart';

class HomeVM extends ChangeNotifier {
  List<PantryItem> get activeItems =>
      Services.pantry.getAll().where((i) => i.isActive).toList();

  int get totalItems => activeItems.length;
  int get expiringSoon =>
      activeItems.where((i) => i.daysUntilExpiry <= 2).length;

  List<PantryItem> get useFirst {
    final list = activeItems;
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  /// "Suggested Groceries" derived from current pantry state.
  List<Map<String, String>> get suggestions {
    final result = <Map<String, String>>[];
    final expired = activeItems
        .where((i) => i.daysUntilExpiry <= 0)
        .take(2)
        .toList();
    final lowStock = activeItems
        .where((i) => i.daysUntilExpiry > 0 && i.daysUntilExpiry <= 3)
        .take(1)
        .toList();
    for (final i in expired) {
      result.add({'name': i.name, 'reason': 'Expired', 'type': 'expired'});
    }
    for (final i in lowStock) {
      result.add({
        'name': i.name,
        'reason': 'Expiring in ${i.daysUntilExpiry} day${i.daysUntilExpiry == 1 ? '' : 's'}',
        'type': 'low',
      });
    }
    return result;
  }
}

final homeVM = HomeVM();
