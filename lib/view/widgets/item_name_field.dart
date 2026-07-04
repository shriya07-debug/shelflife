import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/known_item.dart';
import '../../repo/services.dart';

/// Text field with dropdown autocomplete based on the KnownItems catalog.
/// When user selects a suggestion, callback fires with the full KnownItem
/// so the caller can prefill category, image, unit, etc.
class ItemNameField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(KnownItem picked)? onPicked;
  final String? hintText;
  final Widget? prefixIcon;
  final bool autofocus;
  final InputDecoration? decoration;

  const ItemNameField({
    super.key,
    required this.controller,
    this.onPicked,
    this.hintText = 'e.g. Fresh Chicken Breast',
    this.prefixIcon,
    this.autofocus = false,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<KnownItem>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (val) {
        return Services.knownItems.search(val.text, limit: 5);
      },
      displayStringForOption: (opt) => opt.name,
      fieldViewBuilder: (ctx, textCtrl, focusNode, onSubmit) {
        // Sync external controller with the Autocomplete's controller
        textCtrl.text = controller.text;
        textCtrl.selection =
            TextSelection.collapsed(offset: textCtrl.text.length);
        textCtrl.addListener(() {
          if (controller.text != textCtrl.text) {
            controller.text = textCtrl.text;
          }
        });
        controller.addListener(() {
          if (textCtrl.text != controller.text) {
            textCtrl.text = controller.text;
          }
        });
        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          autofocus: autofocus,
          decoration: (decoration ??
                  InputDecoration(
                    hintText: hintText,
                    prefixIcon: prefixIcon ??
                        const Icon(Icons.shopping_basket_outlined),
                  ))
              .copyWith(
            suffixIcon: textCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      textCtrl.clear();
                      controller.clear();
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 40, height: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: opt.imageAsset != null
                            ? Image.asset(opt.imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.chipBg(ctx),
                                      child: Icon(Icons.image_not_supported,
                                          color: AppColors.textMut(ctx),
                                          size: 16),
                                    ))
                            : Container(
                                color: AppColors.chipBg(ctx),
                                child: Icon(Icons.shopping_basket_outlined,
                                    color: AppColors.textMut(ctx), size: 18),
                              ),
                      ),
                    ),
                    title: Text(opt.name,
                        style: TextStyle(
                            color: AppColors.textPri(ctx),
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(opt.category,
                        style: TextStyle(
                            color: AppColors.textSec(ctx), fontSize: 12)),
                    onTap: () {
                      onSelected(opt);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (opt) {
        controller.text = opt.name;
        onPicked?.call(opt);
      },
    );
  }
}
