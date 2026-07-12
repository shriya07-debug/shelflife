import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'add_item_screen.dart';
import 'recipe_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;

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
      body: pages[_currentIndex],
      bottomNavigationBar: ShelfBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}