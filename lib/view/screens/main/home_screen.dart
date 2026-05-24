import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/home_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';
import '../recipes/use_first_all_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: pantryVM,
        builder: (ctx) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Pantry Insights',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      label: 'Total Items',
                      value: '${homeVM.totalItems}',
                      trailing: const Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: AppColors.safe, size: 16),
                          SizedBox(width: 4),
                          Text('+12%',
                              style: TextStyle(
                                color: AppColors.safe,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      context,
                      label: 'Expiring Soon',
                      value: homeVM.expiringSoon.toString().padLeft(2, '0'),
                      valueColor: AppColors.warning,
                      trailing: Text('Next 48h',
                          style: TextStyle(
                              color: AppColors.textSec(context),
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _wasteCard(context),
              const SizedBox(height: 16),
              _suggestedGroceriesCard(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Use First',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UseFirstAllScreen()),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (homeVM.useFirst.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'No items in pantry yet. Add some!',
                      style: TextStyle(color: AppColors.textSec(context)),
                    ),
                  ),
                )
              else
                ...homeVM.useFirst.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PantryItemCard(
                        item: item,
                        compact: true,
                        onTap: () =>
                            showPantryItemSheet(context, existing: item),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(BuildContext context,
      {required String label,
      required String value,
      Color? valueColor,
      Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPri(context),
              )),
          const SizedBox(height: 4),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _wasteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wasted Items',
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 13)),
                const SizedBox(height: 8),
                const Text('14.2%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    )),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 70,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barGroups: [
                    _bar(0, 5),
                    _bar(1, 6),
                    _bar(2, 3),
                    _bar(3, 9, color: AppColors.danger),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BarChartGroupData _bar(int x, double y,
      {Color color = const Color(0xFFF77272)}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _suggestedGroceriesCard(BuildContext context) {
    final suggestions = homeVM.suggestions;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suggested Groceries',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              Icon(Icons.shopping_cart_outlined,
                  color: AppColors.textPri(context)),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing to restock right now.',
                  style: TextStyle(color: AppColors.textSec(context))),
            )
          else
            ...suggestions.asMap().entries.map((entry) {
              final g = entry.value;
              final last = entry.key == suggestions.length - 1;
              final type = g['type']!;
              final reasonColor = type == 'expired'
                  ? AppColors.danger
                  : AppColors.warning;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['name']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPri(context),
                                  )),
                              const SizedBox(height: 2),
                              Text(g['reason']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: reasonColor,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline,
                            color: AppColors.primary, size: 28),
                      ],
                    ),
                    if (!last)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Divider(
                            height: 1, color: AppColors.divider(context)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
