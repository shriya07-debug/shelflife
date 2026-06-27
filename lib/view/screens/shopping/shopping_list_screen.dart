import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: isDark ? AppColors.primary : AppColors.primaryDark),
            onPressed: () => _addDialog(context),
          ),
        ],
      ),
      body: VMListener(
        listenable: shoppingVM,
        builder: (ctx) {
          final items = shoppingVM.all;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shopping List',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        )),
                    Text(
                        '${items.length} items • ${shoppingVM.checkedCount} ticked',
                        style: TextStyle(
                            color: AppColors.textSec(context), fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Remove',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              shoppingVM.delete(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${item.name} removed.'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () =>
                                        shoppingVM.add(item),
                                  ),
                                ),
                              );
                            },
                            child: _tile(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: VMListener(
        listenable: shoppingVM,
        builder: (ctx) {
          final count = shoppingVM.checkedCount;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: AppColors.bg(context),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (count == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Tick items first to add them to pantry.')),
                    );
                    return;
                  }
                  final moved = await shoppingVM.moveCheckedToPantry();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('$moved item(s) added to pantry.')),
                    );
                  }
                },
                icon: const Icon(Icons.kitchen),
                label: Text(count > 0
                    ? 'Add $count item(s) to Pantry'
                    : 'Add Checked Items to Pantry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, ShoppingItem item) {
    return InkWell(
      onTap: () => shoppingVM.toggleChecked(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (_) => shoppingVM.toggleChecked(item),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.checked
                          ? AppColors.textMut(context)
                          : AppColors.textPri(context),
                      decoration:
                          item.checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.note != null) ...[
                    const SizedBox(height: 2),
                    Text(item.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: AppColors.textSec(context)),
              onPressed: () => shoppingVM.delete(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text('Your shopping list is empty.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context),
              )),
          const SizedBox(height: 6),
          Text('Tap + to add items.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMut(context))),
        ],
      ),
    );
  }

  void _addDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Shopping List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(hintText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                Navigator.pop(context);
                return;
              }
              shoppingVM.add(ShoppingItem(
                id: 's_${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
