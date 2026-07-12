#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6.2 — REMOVE HIVE (fully on Firebase + device prefs)
# =============================================================================
# Your food data is already 100% Firestore. Hive only held the device dark-mode
# preference. This moves that to shared_preferences and removes Hive entirely.
#
#   settings_repo_impl.dart : Hive box  -> shared_preferences   (overwritten)
#   services.dart           : drop Hive.initFlutter + hive import
#   DELETE (dead, unused)   : pantry_repo_impl / shopping_repo_impl /
#                             favorites_repo_impl  (Firebase impls replaced them)
#   pubspec                 : remove hive + hive_flutter, add shared_preferences
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v6_2_remove_hive.sh .
#   chmod +x v6_2_remove_hive.sh && ./v6_2_remove_hive.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/repo/pantry_repo_firebase_impl.dart" ] || { err "Run v5.0 (Piece 4) first."; exit 1; }

info "Adding shared_preferences..."
flutter pub add shared_preferences

info "Rewriting settings_repo_impl.dart (shared_preferences)..."
cat > lib/repo/settings_repo_impl.dart <<'DART'
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_repo.dart';

/// Device-level settings backed by shared_preferences (available before login).
class SettingsRepoImpl implements SettingsRepo {
  late final SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  bool get darkMode => _prefs.getBool('darkMode') ?? false;

  @override
  Future<void> setDarkMode(bool v) async => _prefs.setBool('darkMode', v);

  @override
  bool get seeded => _prefs.getBool('seeded') ?? false;

  @override
  Future<void> markSeeded() async => _prefs.setBool('seeded', true);

  @override
  Future<void> clearSeeded() async => _prefs.remove('seeded');
}
DART
ok "settings_repo_impl.dart on shared_preferences."

info "Removing Hive from services.dart..."
python3 - <<'PY'
import sys
p = "lib/repo/services.dart"
s = open(p, encoding="utf-8").read()
E = [
  ("import 'package:hive_flutter/hive_flutter.dart';\n", ""),
  ("    await Hive.initFlutter();\n", ""),
  ("  ///  • [settings] (device-level, Hive) and [recipes] (static) are ready after\n",
   "  ///  • [settings] (device-level) and [recipes] (static) are ready after\n"),
]
fail = [i for i, (o, _) in enumerate(E) if s.count(o) != 1]
if fail:
    print("ABORT: services anchors %s not found." % fail); sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in E:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("  patched services.dart")
if "Hive" in s:
    print("  WARN: 'Hive' still appears in services.dart — check manually.")
PY

info "Deleting dead Hive impls..."
GIT=0; git rev-parse --is-inside-work-tree >/dev/null 2>&1 && GIT=1
for f in lib/repo/pantry_repo_impl.dart lib/repo/shopping_repo_impl.dart lib/repo/favorites_repo_impl.dart; do
  if [ -f "$f" ]; then
    if [ "$GIT" = "1" ] && git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
      git rm -q -f "$f"; echo "   git rm  $f"
    else
      rm -f "$f"; echo "   rm      $f"
    fi
  fi
done

info "Removing Hive dependency..."
flutter pub remove hive hive_flutter || warn "hive already removed?"

echo
info "Sanity: any remaining Hive references in lib/?"
if grep -rn "hive\|Hive" lib/ --include="*.dart" | grep -v "//"; then
  warn "^ Hive still referenced above (likely just comments). Errors? send them to me."
else
  ok "No Hive references left in lib/."
fi

echo
info "flutter clean + pub get (native deps changed)..."
flutter clean && flutter pub get
echo
ok "v6.2 complete — Hive removed."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. App launches; toggle Dark Mode in Profile -> restart app -> it persists."
echo "   2. Pantry/shopping/favorites/profile all still load from Firestore."
echo "   3. grep -rn 'hive' pubspec.yaml  -> nothing."
echo
echo "  Then: git add -A && git commit -m 'v6.2: remove Hive (shared_preferences for device prefs)' && git tag v6.2"
