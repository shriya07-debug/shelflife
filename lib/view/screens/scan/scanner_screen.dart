import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../model/pantry_item.dart';
import '../../../repo/services.dart';
import '../../../service/off_service.dart';
import '../../../viewmodel/pantry_vm.dart';

/// Returned to the Add-Item screen when the user picks "Edit in full form".
class ScanPrefill {
  final String? barcode;
  final String? name;
  final String? category;
  final int? shelfLifeDays;
  final String? imageUrl;
  const ScanPrefill({
    this.barcode,
    this.name,
    this.category,
    this.shelfLifeDays,
    this.imageUrl,
  });
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;
    _busy = true;
    await _controller.stop();
    final prefill = await _handle(raw.trim());
    if (!mounted) return;
    if (prefill != null) {
      Navigator.pop(context, prefill); // leave scanner to finish in the form
      return;
    }
    await _controller.start(); // resume for the next scan (quick-add)
    _busy = false;
  }

  Future<ScanPrefill?> _handle(String barcode) async {
    ScannedProduct? product = await Services.products.getCached(barcode);
    if (product == null) {
      product = await OffService.lookup(barcode);
      if (product != null) await Services.products.cache(product);
    }
    if (!mounted) return null;
    final existing = Services.pantry.getAll();
    final isDup = existing.any((i) => i.barcode == barcode) ||
        (product != null &&
            existing.any(
                (i) => i.name.toLowerCase() == product!.name.toLowerCase()));
    return _showSheet(barcode, product, isDup);
  }

  Future<ScanPrefill?> _showSheet(
      String barcode, ScannedProduct? product, bool isDup) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    var category = product?.category ?? 'Other';
    final shelfDays = product?.shelfLifeDays ?? 30;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product == null ? 'Product not found' : 'Scan result',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(ctx))),
              if (product == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      "Barcode $barcode isn't in Open Food Facts. Add details manually.",
                      style: TextStyle(
                          color: AppColors.textSec(ctx), fontSize: 13)),
                ),
              if (isDup)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text('This looks like it is already in your pantry.',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 13))),
                  ]),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setSheet(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppCategories.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setSheet(() => category = v ?? category),
              ),
              const SizedBox(height: 8),
              Text('Estimated expiry: $shelfDays days (editable in the form)',
                  style:
                      TextStyle(color: AppColors.textSec(ctx), fontSize: 12)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'edit'),
                    child: const Text('Edit in full form'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: nameCtrl.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(ctx, 'add'),
                    child: const Text('Add to pantry'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    nameCtrl.dispose();

    if (action == 'add' && name.isNotEmpty) {
      await _add(barcode, name, category, shelfDays, product?.imageUrl);
      return null; // stay in scanner (quick-add)
    }
    if (action == 'edit') {
      return ScanPrefill(
        barcode: barcode,
        name: name.isEmpty ? null : name,
        category: category,
        shelfLifeDays: shelfDays,
        imageUrl: product?.imageUrl,
      );
    }
    return null;
  }

  Future<void> _add(String barcode, String name, String category,
      int shelfDays, String? imageUrl) async {
    final now = DateTime.now();
    final item = PantryItem(
      id: 'p_${now.microsecondsSinceEpoch}',
      name: name,
      category: category,
      quantity: 1,
      unitCode: 'unit',
      expiryDate: now.add(Duration(days: shelfDays)),
      addedDate: now,
      purchaseDate: now,
      imageUrl: imageUrl,
      barcode: barcode,
    );
    await pantryVM.add(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name added.'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text(
                'Point at a barcode. Scan several in a row.',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
