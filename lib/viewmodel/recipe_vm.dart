import 'package:flutter/foundation.dart';
import '../model/recipe.dart';
import '../repo/services.dart';

class RecipeVM extends ChangeNotifier {
  String _query = '';
  int? _maxMinutes; // null = any

  String get query => _query;
  int? get maxMinutes => _maxMinutes;
  bool get isSearching => _query.trim().isNotEmpty || _maxMinutes != null;

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setMaxMinutes(int? m) {
    _maxMinutes = m;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _maxMinutes = null;
    notifyListeners();
  }

  // ---- Lists --------------------------------------------------------------
  List<Recipe> get all => Services.recipes.getAll();
  List<Recipe> get useFirst => Services.recipes.getUseFirst();
  List<Recipe> get matches => Services.recipes.getMatches();

  List<Recipe> get favorites {
    final favIds = Services.favorites.getAll();
    return all.where((r) => favIds.contains(r.id)).toList();
  }

  bool isFavorite(String recipeId) => Services.favorites.isFavorite(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    await Services.favorites.toggle(recipeId);
    notifyListeners();
  }

  /// Search results — name, ingredients, AND optional time filter.
  List<Recipe> get searchResults {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      // Time filter
      if (_maxMinutes != null && r.timeMinutes > _maxMinutes!) return false;
      // Text filter
      if (q.isEmpty) return true;
      if (r.title.toLowerCase().contains(q)) return true;
      for (final ing in r.ingredients) {
        if (ing.toLowerCase().contains(q)) return true;
      }
      for (final tag in r.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }
}

final recipeVM = RecipeVM();
