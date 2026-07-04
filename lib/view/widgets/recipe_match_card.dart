import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../constants/app_colors.dart';
import '../../model/recipe.dart';
import '../../viewmodel/recipe_vm.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import 'vm_listener.dart';

class RecipeMatchCard extends StatelessWidget {
  final Recipe recipe;
  final bool showUrgentBadge;
  const RecipeMatchCard({
    super.key,
    required this.recipe,
    this.showUrgentBadge = false,
  });

  Future<bool> _imageExists(String? path) async {
    if (path == null) return false;
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: recipeVM,
      builder: (ctx) {
        final fav = recipeVM.isFavorite(recipe.id);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: FutureBuilder<bool>(
                        future: _imageExists(recipe.imageAsset),
                        builder: (_, snap) {
                          if (snap.data == true) {
                            return Image.asset(
                              recipe.imageAsset!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            height: 120,
                            color: AppColors.chipBg(context),
                            child: Center(
                              child: Icon(Icons.restaurant_menu,
                                  color: AppColors.textMut(context),
                                  size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                    if (showUrgentBadge && recipe.urgent)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Use First',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          await recipeVM.toggleFavorite(recipe.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: fav
                                ? AppColors.danger
                                : AppColors.textSec(context),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: AppColors.textSec(context), size: 12),
                          const SizedBox(width: 4),
                          Text(recipe.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              )),
                          const SizedBox(width: 8),
                          Text('• ${recipe.difficulty}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              )),
                        ],
                      ),
                      if (!recipe.allFound && recipe.missingNote != null) ...[
                        const SizedBox(height: 4),
                        Text(recipe.missingNote!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
