import '../model/recipe.dart';

abstract class RecipeRepo {
  List<Recipe> getAll();
  Recipe? getById(String id);
  List<Recipe> getUseFirst();
  List<Recipe> getMatches();
}
