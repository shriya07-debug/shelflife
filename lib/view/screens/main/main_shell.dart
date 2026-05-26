import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'add_item_screen.dart';
import 'recipe_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatelessWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const PantryScreen(),
      const AddItemScreen(),
      const RecipeScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[initialIndex],
      bottomNavigationBar: ShelfBottomNav(currentIndex: initialIndex),
    );
  }
}
