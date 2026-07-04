import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/recipe_match_card.dart';
import '../../widgets/vm_listener.dart';
import 'favorites_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: recipeVM,
      builder: (ctx) {
        final searching = recipeVM.isSearching;
        final list = searching ? recipeVM.searchResults : recipeVM.all;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.pageHPad, 12, AppSizes.pageHPad, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Recipes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                    ),
                    IconButton(
                      icon: Icon(
                          _showSearch ? Icons.close : Icons.search,
                          color: AppColors.textPri(context)),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchCtrl.clear();
                            recipeVM.clear();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite_border,
                          color: AppColors.textPri(context)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FavoritesScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.pageHPad, 0, AppSizes.pageHPad, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: recipeVM.setQuery,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, ingredient, or tag…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                color: AppColors.textMut(context), size: 56),
                            const SizedBox(height: 10),
                            Text('No recipes match',
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.pageHPad, 8, AppSizes.pageHPad, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => RecipeMatchCard(
                          recipe: list[i],
                          showUrgentBadge: true,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
