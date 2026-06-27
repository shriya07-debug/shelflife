import 'package:flutter/material.dart';
import '../repo/services.dart';
import '../view/theme/theme_controller.dart';
import 'pantry_vm.dart';
import 'shopping_vm.dart';
import 'recipe_vm.dart';

class ProfileVM extends ChangeNotifier {
  bool get darkMode => Services.settings.darkMode;

  Future<void> setDarkMode(bool v) async {
    await Services.settings.setDarkMode(v);
    themeController.value = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Logout — soft sign-out. No data wipe.
  void logout() {
    // No-op besides UI nav. (Auth integration would clear session here.)
  }

  /// Delete account — wipes Hive boxes.
  Future<void> deleteAccount() async {
    await Services.pantry.clear();
    await Services.shopping.clear();
    await Services.favorites.clear();
    await Services.settings.clearSeeded();
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await Services.resetAndReseed();
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    notifyListeners();
  }
}

final profileVM = ProfileVM();
