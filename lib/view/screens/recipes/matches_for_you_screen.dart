import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import 'recipe_match_card.dart';

class MatchesForYouScreen extends StatelessWidget {
  const MatchesForYouScreen({super.key});

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
          final recipes = recipeVM.all.where((r) => !r.urgent).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Matches for you',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('Recipes that match your selected ingredients.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              ...recipes.map((r) => Padding(
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
