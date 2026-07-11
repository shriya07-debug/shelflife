#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6.1a — SYNC PASS (quick fixes)
# =============================================================================
# 1. add_item "Quick-add mode" button (was a dead onTap: (){}) -> opens scanner
# 2. home "Wasted Items 14.2%" (hardcoded) -> real % of expired items in pantry
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v6_1a_sync_quick.sh .
#   chmod +x v6_1a_sync_quick.sh && ./v6_1a_sync_quick.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
grep -q "_openScanner" lib/view/screens/main/add_item_screen.dart || { err "Run v6 (6.sh) first."; exit 1; }

info "Applying sync fixes (all-or-nothing)..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/view/screens/main/add_item_screen.dart": [
    ("""                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Icon(Icons.playlist_add, color: AppColors.primaryDark),""",
     """                  GestureDetector(
                    onTap: _openScanner,
                    child: const Row(
                      children: [
                        Icon(Icons.playlist_add, color: AppColors.primaryDark),"""),
  ],
  "lib/viewmodel/home_vm.dart": [
    ("  int get totalItems => activeItems.length;\n",
     "  int get totalItems => activeItems.length;\n\n"
     "  /// Share of current pantry items that are already past their expiry.\n"
     "  double get wastedPercent {\n"
     "    final all = activeItems;\n"
     "    if (all.isEmpty) return 0;\n"
     "    final expired = all.where((i) => i.daysUntilExpiry < 0).length;\n"
     "    return expired / all.length * 100;\n"
     "  }\n"),
  ],
  "lib/view/screens/main/home_screen.dart": [
    ("""                const Text('14.2%',
                    style: TextStyle(""",
     """                Text('${homeVM.wastedPercent.toStringAsFixed(1)}%',
                    style: TextStyle("""),
  ],
}

fail = []; cache = {}
for path, edits in EDITS.items():
    try: s = open(path, encoding="utf-8").read()
    except FileNotFoundError: fail.append("MISSING: " + path); continue
    cache[path] = s
    for i, (old, new) in enumerate(edits):
        if s.count(old) != 1:
            fail.append("%s: anchor #%d found %dx (need 1)" % (path, i, s.count(old)))
if fail:
    print("ABORT — no files changed:")
    for f in fail: print("   - " + f)
    sys.exit(1)
for path, edits in EDITS.items():
    s = cache[path]
    open(path + ".bak", "w", encoding="utf-8").write(s)
    for old, new in edits: s = s.replace(old, new, 1)
    open(path, "w", encoding="utf-8").write(s)
    print("   patched " + path)
PY
ok "Patches applied."

flutter pub get
echo
ok "v6.1a complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Add Item -> tap 'Quick-add mode' (top-right) -> scanner opens."
echo "   2. Home 'Wasted Items' now shows a real % (0.0% with fresh items;"
echo "      add an item with a past expiry date -> the % rises)."
echo
echo "  Then: git add -A && git commit -m 'v6.1a: sync quick fixes' && git tag v6.1a"
echo "  Next: v6.1b (Edit Profile real save + notifications toggle)."
