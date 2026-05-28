import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    {
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.danger,
      'title': 'Whole Milk expires today',
      'subtitle': 'Use it for the Spaghetti Carbonara recipe.',
      'time': '2h ago',
    },
    {
      'icon': Icons.calendar_today,
      'color': AppColors.warning,
      'title': 'Baby Spinach expires in 2 days',
      'subtitle': 'Try our Spinach & Berry Summer Salad.',
      'time': '8h ago',
    },
    {
      'icon': Icons.shopping_cart,
      'color': AppColors.primary,
      'title': 'Milk added to shopping list',
      'subtitle': 'Low stock alert was triggered.',
      'time': 'Yesterday',
    },
  ];

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 16),
          ..._items.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: (n['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n['icon'] as IconData,
                          color: n['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPri(context),
                              )),
                          const SizedBox(height: 2),
                          Text(n['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSec(context),
                              )),
                          const SizedBox(height: 4),
                          Text(n['time'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMut(context),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
