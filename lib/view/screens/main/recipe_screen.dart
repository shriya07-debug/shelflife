import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/vm_listener.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/use_first_recipes_screen.dart';
import '../recipes/matches_for_you_screen.dart';
import '../recipes/favorites_screen.dart';
import '../recipes/recipe_match_card.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _searchCtrl = TextEditingController();
  final List<String> _selectedIngredients = ['Chicken Breast', 'Bell Peppers'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          return Column(
            children: [
              _searchBar(context),
              if (recipeVM.maxMinutes != null) _activeFilterBar(context),
              Expanded(
                child: recipeVM.isSearching
                    ? _searchResults(context)
                    : _defaultRecipeView(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: recipeVM.setQuery,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search recipes by name or ingredient',
          filled: true,
          fillColor: AppColors.card(context),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recipeVM.query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchCtrl.clear();
                    recipeVM.setQuery('');
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.timer_outlined,
                  color: recipeVM.maxMinutes != null
                      ? AppColors.primaryDark
                      : AppColors.textMut(context),
                ),
                onPressed: () => _showTimeFilter(context),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showTimeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          int? current = recipeVM.maxMinutes;
          final options = [null, 5, 15, 30, 60];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Max cooking time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((o) {
                    final selected = current == o;
                    final label = o == null ? 'Any' : '≤ $o min';
                    return GestureDetector(
                      onTap: () {
                        recipeVM.setMaxMinutes(o);
                        Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.chipUnsel(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPri(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _activeFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Chip(
            label: Text('≤ ${recipeVM.maxMinutes} min'),
            backgroundColor: AppColors.primaryLight,
            labelStyle: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            deleteIcon: const Icon(Icons.close,
                size: 16, color: AppColors.primaryDark),
            onDeleted: () => recipeVM.setMaxMinutes(null),
          ),
        ],
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    final results = recipeVM.searchResults;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          children: [
            Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                recipeVM.clear();
              },
              child: const Text('Clear all',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: AppColors.textMut(context)),
                  const SizedBox(height: 12),
                  Text('No recipes match.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSec(context))),
                ],
              ),
            ),
          )
        else
          ...results.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RecipeMatchCard(recipe: r),
              )),
      ],
    );
  }

  Widget _defaultRecipeView(BuildContext context) {
    final useFirst = recipeVM.useFirst;
    final smallSet =
        recipeVM.all.where((r) => !r.urgent).take(2).toList();
    final favorites = recipeVM.favorites;
    final matches = recipeVM.matches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Use First Suggestions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UseFirstRecipesScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (useFirst.isNotEmpty) _featuredCard(useFirst.first),
        const SizedBox(height: 12),
        if (smallSet.length >= 2)
          Row(
            children: [
              Expanded(child: _smallRecipe(smallSet[0])),
              const SizedBox(width: 12),
              Expanded(child: _smallRecipe(smallSet[1])),
            ],
          ),
        const SizedBox(height: 24),
        Text('Find by Ingredients',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedIngredients.map((i) => Chip(
                  label: Text(i,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      )),
                  backgroundColor: AppColors.primaryLight,
                  deleteIcon: const Icon(Icons.close,
                      size: 16, color: AppColors.primaryDark),
                  onDeleted: () =>
                      setState(() => _selectedIngredients.remove(i)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                )),
            ActionChip(
              label: Icon(Icons.add,
                  size: 18, color: AppColors.textPri(context)),
              backgroundColor: AppColors.card(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.divider(context)),
              ),
              onPressed: _addIngredientDialog,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Favorites section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.danger, size: 22),
                const SizedBox(width: 6),
                Text('Favorite Recipes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          _emptyFavorites(context)
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _favoriteCard(favorites[i]),
            ),
          ),
        const SizedBox(height: 24),
        // Matches
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Matches for you',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MatchesForYouScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...matches.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecipeMatchCard(recipe: r),
            )),
      ],
    );
  }

  void _addIngredientDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Onion'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty &&
                  !_selectedIngredients.contains(name)) {
                setState(() => _selectedIngredients.add(name));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: r.imageAsset != null
                ? Image.asset(
                    r.imageAsset!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _featuredFallback(),
                  )
                : _featuredFallback(),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14, bottom: 14, right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('HIGH URGENCY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                ),
                const SizedBox(height: 8),
                Text(r.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(r.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _featuredFallback() {
    return Container(
      height: 200,
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _smallRecipe(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Container(
        height: 130,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned.fill(
              child: r.imageAsset != null
                  ? Image.asset(
                      r.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _smallFallback(),
                    )
                  : _smallFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10, bottom: 10, right: 10,
              child: Text(r.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Container _smallFallback() {
    return Container(
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white),
      ),
    );
  }

  Widget _favoriteCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: SizedBox(
        width: 180,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: r.imageAsset != null
                    ? Image.asset(r.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppColors.chipBg(context),
                              child: Icon(Icons.restaurant,
                                  color: AppColors.textMut(context),
                                  size: 32),
                            ))
                    : Container(
                        color: AppColors.chipBg(context),
                        child: Icon(Icons.restaurant,
                            color: AppColors.textMut(context), size: 32),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPri(context),
                        )),
                    const SizedBox(height: 4),
                    Text('${r.time} • ${r.difficulty}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyFavorites(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border,
              color: AppColors.textMut(context), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No favorites yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text('Tap the heart on a recipe to save it here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
