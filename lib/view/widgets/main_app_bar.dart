import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/misc/notifications_screen.dart';
import 'app_logo.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primary : AppColors.primaryDark;
    return AppBar(
      automaticallyImplyLeading: false,
      title: const AppLogoText(height: 30),
      leading: IconButton(
        icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: AppColors.textPri(context)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }
}
