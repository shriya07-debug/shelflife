import 'package:flutter/material.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import 'pantry_item_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: pantryVM,
      builder: (ctx) {
        final items = pantryVM.filtered;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.pageHPad, 8, AppSizes.pageHPad, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: pantryVM.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search items…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: pantryVM.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            pantryVM.setQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageHPad),
                itemCount: AppCategories.filterChips.length,
                itemBuilder: (_, i) {
                  final label = AppCategories.filterChips[i];
                  final on = pantryVM.filter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => pantryVM.setFilter(label),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.primary
                              : AppColors.chipBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              color: on
                                  ? Colors.white
                                  : AppColors.textPri(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? _emptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.pageHPad, 4, AppSizes.pageHPad, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Dismissible(
                          key: ValueKey('pantry_${item.id}'),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: AppColors.safe,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async => true,
                          onDismissed: (dir) async {
                            if (dir == DismissDirection.startToEnd) {
                              // Right swipe: finish
                              final wasStatus = item.status;
                              await pantryVM.markFinished(item);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${item.name} marked finished'),
                                    action: SnackBarAction(
                                      label: AppStrings.undo,
                                      onPressed: () async {
                                        if (wasStatus.name == 'active') {
                                          await pantryVM.markActive(item);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                            } else {
                              final removed = item;
                              await pantryVM.delete(item.id);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('${removed.name} deleted'),
                                    action: SnackBarAction(
                                      label: AppStrings.undo,
                                      onPressed: () async {
                                        await pantryVM.add(removed);
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: PantryItemCard(
                            item: item,
                            onFavoriteToggle: () =>
                                pantryVM.toggleFavorite(item),
                            onTap: () =>
                                showPantryItemSheet(ctx, existing: item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              color: AppColors.textMut(context), size: 64),
          const SizedBox(height: 12),
          Text('No items match your filter',
              style: TextStyle(color: AppColors.textSec(context))),
        ],
      ),
    );
  }
}
