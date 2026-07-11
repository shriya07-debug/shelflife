#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6 — REAL BARCODE SCANNING + PRODUCT DATABASE
# =============================================================================
# Built in parts, all concatenated into this one file.
#
#   PART 1  deps + Android camera permission        [present]
#   PART 2  PantryItem.barcode field                [present]
#   PART 3  product cache repo + Open Food Facts     [present]
#   PART 4  scanner screen                           [present]
#   PART 5  wire the Barcode Scan toggle             [present]
#
# STATUS: COMPLETE (all 5 parts)
#
# After running: re-publish firestore.rules (adds 'products'), and test barcode
# scanning on a REAL Android device (the emulator camera can't focus on codes).
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/6.sh .
#   chmod +x 6.sh && ./6.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
grep -q "cloud_firestore" pubspec.yaml || { err "Run v5.0 first."; exit 1; }

# =============================================================================
# PART 1 — Dependencies + Android camera permission
# =============================================================================
info "PART 1: adding mobile_scanner (pinned) + http..."
# mobile_scanner's API changed across majors; pin to the 5.x line this code targets.
flutter pub add mobile_scanner:^5.2.3 http
ok "Dependencies added."

info "PART 1: ensuring Android CAMERA permission..."
python3 - <<'PY'
import re, sys
M = "android/app/src/main/AndroidManifest.xml"
try:
    x = open(M, encoding="utf-8").read()
except FileNotFoundError:
    print("  WARN: %s not found; add CAMERA permission manually." % M); sys.exit(0)
orig = x
lines = [
    '    <uses-permission android:name="android.permission.CAMERA"/>',
    '    <uses-feature android:name="android.hardware.camera" android:required="false"/>',
]
add = [l for l in lines if l.strip() not in x]
if add:
    # insert right after the opening <manifest ...> tag
    m = re.search(r"<manifest[^>]*>", x)
    if not m:
        print("  WARN: <manifest> tag not found; add CAMERA permission manually."); sys.exit(0)
    ins = "\n" + "\n".join(add)
    x = x[:m.end()] + ins + x[m.end():]
    open(M + ".bak", "w", encoding="utf-8").write(orig)
    open(M, "w", encoding="utf-8").write(x)
    print("  added CAMERA permission to AndroidManifest.xml (backup .bak)")
else:
    print("  CAMERA permission already present.")
PY
ok "PART 1 done."

# =============================================================================
# PART 2 — PantryItem.barcode field
# =============================================================================
info "PART 2: adding barcode field to PantryItem..."
python3 - <<'PY'
import sys
p = "lib/model/pantry_item.dart"
s = open(p, encoding="utf-8").read()
E = [
    ("  final String? imageUrl;\n", "  final String? imageUrl;\n  final String? barcode;\n"),
    ("    this.imageUrl,\n", "    this.imageUrl,\n    this.barcode,\n"),
    ("        'imageUrl': imageUrl,\n", "        'imageUrl': imageUrl,\n        'barcode': barcode,\n"),
    ("        imageUrl: m['imageUrl'] as String?,\n", "        imageUrl: m['imageUrl'] as String?,\n        barcode: m['barcode'] as String?,\n"),
    ("    String? imageUrl,\n", "    String? imageUrl,\n    String? barcode,\n"),
    ("        imageUrl: imageUrl ?? this.imageUrl,\n", "        imageUrl: imageUrl ?? this.imageUrl,\n        barcode: barcode ?? this.barcode,\n"),
]
fail = [i for i, (o, _) in enumerate(E) if s.count(o) != 1]
if fail:
    print("ABORT PART 2: anchors %s not uniquely found (run v5.1a-image + v5.1c first?)." % fail)
    sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in E:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("  patched lib/model/pantry_item.dart")
PY
ok "PART 2 done."

# =============================================================================
# PART 3 — Open Food Facts service + shared product cache
# =============================================================================
info "PART 3: writing OFF service + product cache repo..."
mkdir -p lib/service

cat > lib/service/off_service.dart <<'DART'
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A product resolved from Open Food Facts (or the Firestore cache).
class ScannedProduct {
  final String barcode;
  final String name;
  final String category; // mapped to AppCategories
  final int shelfLifeDays; // estimated
  final String? imageUrl;
  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.category,
    required this.shelfLifeDays,
    this.imageUrl,
  });
}

/// Open Food Facts lookup + category/shelf-life heuristics.
class OffService {
  OffService._();

  static const Map<String, int> _shelfLife = {
    'Dairy': 10,
    'Produce': 6,
    'Meat': 4,
    'Grains': 120,
    'Beverages': 90,
    'Snacks': 120,
    'Other': 30,
  };

  static int shelfLifeFor(String category) => _shelfLife[category] ?? 30;

  /// Maps OFF's free-form categories onto the app's fixed AppCategories list.
  static String mapCategory(String raw) {
    final t = raw.toLowerCase();
    bool has(List<String> ks) => ks.any(t.contains);
    if (has(['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'dairy'])) {
      return 'Dairy';
    }
    if (has(['fruit', 'vegetable', 'produce', 'fresh'])) return 'Produce';
    if (has(['meat', 'chicken', 'beef', 'pork', 'fish', 'seafood', 'poultry',
        'sausage'])) {
      return 'Meat';
    }
    if (has(['bread', 'cereal', 'rice', 'pasta', 'grain', 'flour', 'bakery',
        'noodle'])) {
      return 'Grains';
    }
    if (has(['beverage', 'drink', 'juice', 'water', 'soda', 'tea', 'coffee',
        'smoothie'])) {
      return 'Beverages';
    }
    if (has(['snack', 'chip', 'candy', 'chocolate', 'biscuit', 'cookie',
        'sweet', 'confection'])) {
      return 'Snacks';
    }
    return 'Other';
  }

  /// Looks up a barcode on Open Food Facts. Returns null if not found/unknown.
  static Future<ScannedProduct?> lookup(String barcode) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,brands,categories,image_url');
    try {
      final res = await http.get(uri,
          headers: {'User-Agent': 'ShelfLife/6.0 (Flutter app)'});
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null; // 1 = product found
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) return null;
      final name = (p['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;
      final category = mapCategory((p['categories'] as String?) ?? '');
      return ScannedProduct(
        barcode: barcode,
        name: name,
        category: category,
        shelfLifeDays: shelfLifeFor(category),
        imageUrl: p['image_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
DART

cat > lib/repo/product_repo.dart <<'DART'
import '../service/off_service.dart';

/// Shared, barcode-keyed cache of resolved products (foundation from v5.1a).
abstract class ProductRepo {
  /// Returns the cached product for [barcode], or null if not cached.
  Future<ScannedProduct?> getCached(String barcode);

  /// Stores a resolved product in the shared cache.
  Future<void> cache(ScannedProduct product);
}
DART

cat > lib/repo/product_repo_firebase_impl.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/off_service.dart';
import 'product_repo.dart';

/// SHARED cache at Firestore collection 'products', doc id = barcode.
class ProductRepoFirebaseImpl implements ProductRepo {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');

  @override
  Future<ScannedProduct?> getCached(String barcode) async {
    try {
      final m = (await _col.doc(barcode).get()).data();
      if (m == null) return null;
      return ScannedProduct(
        barcode: barcode,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'Other',
        shelfLifeDays: (m['shelfLifeDays'] as num?)?.toInt() ?? 30,
        imageUrl: m['imageUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cache(ScannedProduct p) async {
    await _col.doc(p.barcode).set({
      'name': p.name,
      'category': p.category,
      'shelfLifeDays': p.shelfLifeDays,
      'imageUrl': p.imageUrl,
    });
  }
}
DART
ok "OFF service + product repo written."

info "PART 3: binding product cache in services.dart..."
python3 - <<'PY'
import sys
p = "lib/repo/services.dart"
s = open(p, encoding="utf-8").read()
E = [
    ("import 'profile_repo_firebase_impl.dart';\n",
     "import 'profile_repo_firebase_impl.dart';\nimport 'product_repo.dart';\nimport 'product_repo_firebase_impl.dart';\n"),
    ("  static ProfileRepo get profile => _profile!;\n",
     "  static ProfileRepo get profile => _profile!;\n\n  /// Shared barcode->product cache (stateless; no per-user binding).\n  static final ProductRepo products = ProductRepoFirebaseImpl();\n"),
]
fail = [i for i, (o, _) in enumerate(E) if s.count(o) != 1]
if fail:
    print("ABORT PART 3: services anchors %s not found." % fail); sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in E:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("  patched lib/repo/services.dart")
PY

info "PART 3: updating firestore.rules (adds shared products cache)..."
cat > firestore.rules <<'RULES'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /known_items/{item} {
      allow read, write: if request.auth != null;
    }
    match /products/{barcode} {
      allow read, write: if request.auth != null;
    }
  }
}
RULES
ok "PART 3 done."

# =============================================================================
# PART 4 — Scanner screen
# =============================================================================
info "PART 4: writing scanner screen..."
mkdir -p lib/view/screens/scan
cat > lib/view/screens/scan/scanner_screen.dart <<'DART'
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
DART
ok "PART 4 done."

# =============================================================================
# PART 5 — Wire the Barcode Scan toggle to the scanner
# =============================================================================
info "PART 5: wiring the Barcode Scan toggle..."
python3 - <<'PY'
import sys
p = "lib/view/screens/main/add_item_screen.dart"
s = open(p, encoding="utf-8").read()
E = [
  ("import '../../../repo/known_items_repo.dart';\n",
   "import '../../../repo/known_items_repo.dart';\nimport '../scan/scanner_screen.dart';\n"),
  ("              _mode == 0 ? _manualForm(context) : _barcodePlaceholder(context),\n",
   "              _mode == 0 ? _manualForm(context) : _barcodeScanPanel(context),\n"),
  ("""  Widget _barcodePlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(context), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner,
              size: 80, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text('Point camera at barcode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 8),
          Text(
            'Scanner will be enabled in a future build.',
            style: TextStyle(color: AppColors.textSec(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }""",
   """  Widget _barcodeScanPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(context), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner,
              size: 80, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text('Scan a product barcode',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 8),
          Text(
            'Auto-fills from Open Food Facts. Add several in a row.',
            style: TextStyle(color: AppColors.textSec(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Open Scanner'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<ScanPrefill>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.name != null) _nameCtrl.text = result.name!;
      if (result.category != null &&
          AppCategories.all.contains(result.category)) {
        _category = result.category!;
      }
      if (result.shelfLifeDays != null) {
        _expiry = DateTime.now().add(Duration(days: result.shelfLifeDays!));
      }
      if (result.imageUrl != null) _imageUrlCtrl.text = result.imageUrl!;
      _mode = 0; // drop into the manual form to finish up
    });
  }"""),
]
fail = [i for i, (o, _) in enumerate(E) if s.count(o) != 1]
if fail:
    print("ABORT PART 5: anchors %s not found." % fail); sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in E:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("  patched lib/view/screens/main/add_item_screen.dart")
PY
ok "PART 5 done."

flutter pub get
echo
ok "6.sh COMPLETE — all 5 parts applied."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo
err "RE-PUBLISH RULES: Firebase Console > Firestore > Rules -> paste firestore.rules"
echo "   -> Publish (adds the shared 'products' cache)."
echo
echo "  TEST (use a REAL Android device — the emulator camera can't scan):"
echo "   1. Add Item -> Barcode Scan -> Open Scanner."
echo "   2. Scan a mainstream product -> scan-result sheet with name/category filled."
echo "      'Add to pantry' -> item added; scanner stays open for the next (quick-add)."
echo "   3. Scan the same product again -> 'already in your pantry' warning."
echo "   4. Scan something obscure (not in OFF) -> 'Product not found' ->"
echo "      'Edit in full form' -> manual form opens pre-filled with the barcode."
echo "   5. Firestore: a 'products/<barcode>' cache doc appears; re-scans are instant."
echo
echo "  Then: git add -A && git commit -m 'v6: barcode scanning + product database' && git tag v6"
