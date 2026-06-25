import '../model/recipe.dart';
import 'recipe_repo.dart';
import 'recipe_data.dart';

class RecipeRepoImpl implements RecipeRepo {
  @override
  List<Recipe> getAll() => RecipeData.all;
  @override
  Recipe? getById(String id) => RecipeData.byId(id);
  @override
  List<Recipe> getUseFirst() => RecipeData.useFirst;
  @override
  List<Recipe> getMatches() => RecipeData.matches;
}
