import 'package:flutter/material.dart';
import '../repo/services.dart';
import '../view/theme/theme_controller.dart';
import 'pantry_vm.dart';
import 'shopping_vm.dart';
import 'recipe_vm.dart';
import 'auth_vm.dart';

class ProfileVM extends ChangeNotifier {
  /// Forces listeners to rebuild after Services.profile is updated directly
  /// (profile data isn't cached on this VM itself).
  void refresh() => notifyListeners();

  bool get darkMode => Services.settings.darkMode;

  Future<void> setDarkMode(bool v) async {
    await Services.settings.setDarkMode(v);
    themeController.value = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Logout — signs the user out of Firebase. Local data is left intact.
  Future<void> logout() async {
    await authVM.signOut();
  }

  /// Delete account — removes the Firebase user, then wipes local data.
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> deleteAccount() async {
    // Clear the user's cloud data while still authenticated, THEN delete the
    // auth account (Firestore writes require a live, matching session).
    await Services.pantry.clear();
    await Services.shopping.clear();
    await Services.favorites.clear();
    final error = await authVM.deleteAccount();
    if (error != null) return error;
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    notifyListeners();
    return null;
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
