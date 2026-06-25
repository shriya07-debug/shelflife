import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../model/pantry_item.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = pantryVM.query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Left swipe = delete with undo
  Future<void> _onDelete(PantryItem item) async {
    await pantryVM.delete(item.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted.'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => pantryVM.add(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Right swipe = mark finished + offer to add to shopping list
  Future<bool> _onMarkFinished(PantryItem item) async {
    final addToList = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as finished?'),
        content: Text(
            '${item.name} will be moved to the "Finished" category. Add it to your shopping list too?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, just finish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, add to list'),
          ),
        ],
      ),
    );

    if (addToList == null) return false; // user cancelled

    await pantryVM.markFinished(item);
    if (addToList) {
      await shoppingVM.add(ShoppingItem(
        id: 's_${DateTime.now().microsecondsSinceEpoch}',
        name: item.name,
        note: 'Finished — restock',
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addToList
              ? '${item.name} finished + added to shopping list.'
              : '${item.name} marked as finished.'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () => pantryVM.markActive(item),
          ),
        ),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: pantryVM,
        builder: (ctx) {
          final items = pantryVM.filtered;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: pantryVM.setQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search your pantry...',
                  filled: true,
                  fillColor: AppColors.card(context),
                  suffixIcon: pantryVM.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            pantryVM.setQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppCategories.filterChips.map((f) {
                    final selected = f == pantryVM.filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => pantryVM.setFilter(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.chipUnsel(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (f == 'Favorites') ...[
                                Icon(Icons.favorite,
                                    size: 14,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.danger),
                                const SizedBox(width: 4),
                              ],
                              if (f == 'Finished') ...[
                                Icon(Icons.check_circle,
                                    size: 14,
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 4),
                              ],
                              Text(f,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPri(context),
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                _emptyState(context)
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _swipeWrap(item),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _swipeWrap(PantryItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      // Right swipe (startToEnd) = finish, Left swipe (endToStart) = delete
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.safe,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Finish',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete this item?'),
                  content: Text('Remove "${item.name}" from your pantry?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (ok) await _onDelete(item);
          return ok;
        } else {
          // Mark finished
          return await _onMarkFinished(item);
        }
      },
      child: PantryItemCard(
        item: item,
        showMenu: true,
        onTap: () => showPantryItemSheet(context, existing: item),
        onFavoriteToggle: () => pantryVM.toggleFavorite(item),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text(
            pantryVM.query.isNotEmpty || pantryVM.filter != 'All'
                ? 'No matches found.'
                : 'Your pantry is empty.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSec(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pantryVM.query.isNotEmpty || pantryVM.filter != 'All'
                ? 'Try a different search or filter.'
                : 'Tap + to add your first item.',
            style:
                TextStyle(fontSize: 13, color: AppColors.textMut(context)),
          ),
        ],
      ),
    );
  }
}
