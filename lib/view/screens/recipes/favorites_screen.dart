import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import 'recipe_match_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          final favs = recipeVM.favorites;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite,
                      color: AppColors.danger, size: 26),
                  const SizedBox(width: 8),
                  Text('Favorite Recipes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  '${favs.length} recipe${favs.length == 1 ? '' : 's'} saved.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: AppColors.textMut(context)),
                      const SizedBox(height: 12),
                      Text('No favorites yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSec(context),
                          )),
                      const SizedBox(height: 6),
                      Text('Tap the heart on a recipe to save it here.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMut(context))),
                    ],
                  ),
                )
              else
                ...favs.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecipeMatchCard(recipe: r),
                    )),
            ],
          );
        },
      ),
    );
  }
}
