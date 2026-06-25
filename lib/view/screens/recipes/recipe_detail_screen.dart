import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/vm_listener.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: VMListener(
        listenable: Listenable.merge([pantryVM, shoppingVM, recipeVM]),
        builder: (ctx) {
          final isFav = recipeVM.isFavorite(recipe.id);
          final pantryNames =
              pantryVM.active.map((p) => p.name.toLowerCase()).toSet();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.danger : Colors.white,
                    ),
                    onPressed: () => recipeVM.toggleFavorite(recipe.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageAsset != null
                      ? Image.asset(
                          recipe.imageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF6B7280)),
                        )
                      : const ColoredBox(color: Color(0xFF6B7280)),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.time,
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                            const SizedBox(width: 12),
                            Icon(Icons.local_fire_department_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.difficulty,
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recipe.description.isNotEmpty)
                          Text(recipe.description,
                              style: TextStyle(
                                color: AppColors.textPri(context),
                                fontSize: 14,
                                height: 1.45,
                              )),
                        const SizedBox(height: 16),
                        if (recipe.tags.isNotEmpty)
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: recipe.tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(t,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          )),
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 24),
                        Text('Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map((ing) {
                          final have = pantryNames.any(
                              (p) => p.contains(ing.toLowerCase()));
                          final inList = shoppingVM.all.any((s) =>
                              s.name.toLowerCase() == ing.toLowerCase());
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  have
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color: have
                                      ? AppColors.safe
                                      : AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(ing,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPri(context),
                                      )),
                                ),
                                if (!have)
                                  TextButton.icon(
                                    onPressed: inList
                                        ? null
                                        : () {
                                            shoppingVM.addIngredient(
                                                ing,
                                                'For ${recipe.title}');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  '$ing added to shopping list.'),
                                            ));
                                          },
                                    icon: Icon(
                                      inList
                                          ? Icons.check
                                          : Icons.add_shopping_cart,
                                      size: 16,
                                      color: inList
                                          ? AppColors.safe
                                          : AppColors.primaryDark,
                                    ),
                                    label: Text(
                                      inList ? 'In list' : 'Buy',
                                      style: TextStyle(
                                        color: inList
                                            ? AppColors.safe
                                            : AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
