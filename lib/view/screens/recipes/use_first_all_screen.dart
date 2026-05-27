import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class UseFirstAllScreen extends StatelessWidget {
  const UseFirstAllScreen({super.key});

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
        listenable: pantryVM,
        builder: (ctx) {
          final items = pantryVM.active
            ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Use First',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('${items.length} items sorted by soonest expiry.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Pantry is empty.',
                        style:
                            TextStyle(color: AppColors.textSec(context))),
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PantryItemCard(
                        item: item,
                        compact: true,
                        onTap: () =>
                            showPantryItemSheet(context, existing: item),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
