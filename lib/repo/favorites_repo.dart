abstract class FavoritesRepo {
  Future<void> init();
  Set<String> getAll();
  bool isFavorite(String recipeId);
  Future<void> toggle(String recipeId);
  Future<void> clear();
}
