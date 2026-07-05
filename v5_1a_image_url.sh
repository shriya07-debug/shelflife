#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.1a — IMAGE VIA URL  (part 1 of "Smart add"; autocomplete next)
# =============================================================================
# Adds an optional image URL to pantry items.
#   model/pantry_item.dart        : + imageUrl field (toMap/fromMap/copyWith)
#   screens/main/add_item_screen  : + "Image URL (optional)" field, saved on add
#   widgets/pantry_item_card      : shows the network image when a URL is set,
#                                   otherwise unchanged (falls back to old art)
# Purely additive: items without a URL look exactly as before.
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_1a_image_url.sh .
#   chmod +x v5_1a_image_url.sh && ./v5_1a_image_url.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/model/pantry_item.dart" ] || { err "pantry_item.dart missing."; exit 1; }

info "Applying image-URL patches (all-or-nothing)..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/model/pantry_item.dart": [
    ("  final String? imagePath;\n",
     "  final String? imagePath;\n  final String? imageUrl;\n", 'one'),
    ("    this.imagePath,\n",
     "    this.imagePath,\n    this.imageUrl,\n", 'one'),
    ("        'imagePath': imagePath,\n",
     "        'imagePath': imagePath,\n        'imageUrl': imageUrl,\n", 'one'),
    ("        imagePath: m['imagePath'] as String?,\n",
     "        imagePath: m['imagePath'] as String?,\n        imageUrl: m['imageUrl'] as String?,\n", 'one'),
    ("    String? imageAsset,\n",
     "    String? imageAsset,\n    String? imageUrl,\n", 'one'),
    ("        imageAsset: imageAsset ?? this.imageAsset,\n",
     "        imageAsset: imageAsset ?? this.imageAsset,\n        imageUrl: imageUrl ?? this.imageUrl,\n", 'one'),
  ],
  "lib/view/screens/main/add_item_screen.dart": [
    ("  final _qtyCtrl = TextEditingController(text: '1');\n",
     "  final _qtyCtrl = TextEditingController(text: '1');\n  final _imageUrlCtrl = TextEditingController();\n", 'one'),
    ("    _qtyCtrl.dispose();\n",
     "    _qtyCtrl.dispose();\n    _imageUrlCtrl.dispose();\n", 'one'),
    ("      purchaseDate: _purchase,\n      storage: _storage,\n    );",
     "      purchaseDate: _purchase,\n      storage: _storage,\n      imageUrl: _imageUrlCtrl.text.trim().isEmpty\n          ? null\n          : _imageUrlCtrl.text.trim(),\n    );", 'one'),
    ("    _nameCtrl.clear();\n",
     "    _nameCtrl.clear();\n    _imageUrlCtrl.clear();\n", 'one'),
    ("""          TextField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
          ),
          const SizedBox(height: 14),""",
     """          TextField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
          ),
          const SizedBox(height: 14),
          _formLabel(context, 'Image URL (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _imageUrlCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://.../photo.jpg'),
          ),
          const SizedBox(height: 14),""", 'one'),
  ],
  "lib/view/widgets/pantry_item_card.dart": [
    ("""        child: item.imageAsset != null
            ? Image.asset(
                item.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('img',
                      style: TextStyle(
                          color: AppColors.textMut(context), fontSize: 12)),
                ),
              )
            : Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textMut(context), size: 24),
              ),""",
     """        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textMut(context), size: 24),
                ),
              )
            : item.imageAsset != null
                ? Image.asset(
                    item.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text('img',
                          style: TextStyle(
                              color: AppColors.textMut(context), fontSize: 12)),
                    ),
                  )
                : Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textMut(context), size: 24),
                  ),""", 'one'),
  ],
}

fail = []; cache = {}
for path, edits in EDITS.items():
    try: s = open(path, encoding="utf-8").read()
    except FileNotFoundError: fail.append("MISSING: " + path); continue
    cache[path] = s
    for i, (old, new, mode) in enumerate(edits):
        if s.count(old) != 1:
            fail.append("%s: anchor #%d found %dx (need 1)" % (path, i, s.count(old)))
if fail:
    print("ABORT — no files changed:")
    for f in fail: print("   - " + f)
    print("\n(If already applied, anchors are gone — expected.)")
    sys.exit(1)
for path, edits in EDITS.items():
    s = cache[path]
    open(path + ".bak", "w", encoding="utf-8").write(s)
    for old, new, mode in edits: s = s.replace(old, new, 1)
    open(path, "w", encoding="utf-8").write(s)
    print("   patched " + path)
PY
ok "Patches applied."

flutter pub get
echo
ok "v5.1a-image complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo -e "    ${BLUE}flutter run${NC}"
echo "  TEST:"
echo "   1. Add an item and paste an image URL (e.g. any https://.../photo.jpg)."
echo "      The pantry card shows that image; a bad URL shows a broken-image icon."
echo "   2. Add an item WITHOUT a URL -> looks exactly as before."
echo "   3. Check Firestore: the pantry doc has an 'imageUrl' field."
echo
echo "  Then: git add -A && git commit -m 'v5.1a: item image via URL' && git tag v5.1a-image"
echo "  Tell me when it's good and I'll send the autocomplete half."
