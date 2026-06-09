import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import 'recipe_detail_screen.dart';

class RecipeMatchCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeMatchCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final accent = r.allFound ? AppColors.safe : AppColors.warning;
    final isFav = recipeVM.isFavorite(r.id);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accent, width: 5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: r.imageAsset != null
                  ? Image.asset(
                      r.imageAsset!,
                      width: 70, height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70, height: 70,
                        color: AppColors.chipBg(context),
                        child: Icon(Icons.restaurant,
                            color: AppColors.textMut(context)),
                      ),
                    )
                  : Container(
                      width: 70, height: 70,
                      color: AppColors.chipBg(context),
                      child: Icon(Icons.restaurant,
                          color: AppColors.textMut(context)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 4),
                  Text('${r.time} • ${r.difficulty}',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 13)),
                  const SizedBox(height: 6),
                  if (r.allFound)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safeLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ALL INGREDIENTS FOUND',
                          style: TextStyle(
                            color: AppColors.safe,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          )),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                              '${r.missingIngredients.length} MISSING',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.missingNote ?? '',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: AppColors.textSec(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.danger : AppColors.warning,
              ),
              onPressed: () => recipeVM.toggleFavorite(r.id),
            ),
          ],
        ),
      ),
    );
  }
}
