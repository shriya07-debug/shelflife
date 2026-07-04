#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.0 — PIECE 1 of 4: Firebase initialization  (UI-NEUTRAL)
# =============================================================================
# What this does:
#   • Adds firebase_core, firebase_auth, cloud_firestore to pubspec
#   • Initializes Firebase in main() + enables Firestore offline persistence
#   • Ensures Android minSdk >= 23 (required by firebase_auth)
#
# What this DOES NOT do:
#   • Touch ANY theme, color, size, widget, or screen file
#   • Change app behaviour or navigation (home: is still SplashScreen)
#
# After running, `git diff --name-only` must show ONLY:
#   pubspec.yaml   lib/main.dart   android/app/build.gradle.kts
# If anything under lib/view/ appears, STOP — something is wrong.
#
# Run from the project root:
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   chmod +x v5_0_piece1_firebase_init.sh
#   ./v5_0_piece1_firebase_init.sh
#
# Rollback (git):  git checkout -- pubspec.yaml lib/main.dart android/app/build.gradle.kts
# Rollback (bak):  each edited file has a .bak sibling created below.
# =============================================================================
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

# ---- Pre-flight -------------------------------------------------------------
[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run this from the shelflife/ project root."; exit 1; }

if [ ! -f "lib/firebase_options.dart" ]; then
  err "lib/firebase_options.dart not found. Run 'flutterfire configure' first."; exit 1
fi
ok "firebase_options.dart present."

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -n "$(git status --porcelain)" ]; then
    warn "You have uncommitted changes. Commit or stash first so 'git diff' cleanly shows this piece's blast radius."
    read -r -p "Continue anyway? [y/N] " a; [ "$a" = "y" ] || [ "$a" = "Y" ] || { info "Aborted."; exit 0; }
  fi
else
  warn "Not a git repo — .bak backups will be your only rollback."
fi

# ---- 1. Dependencies --------------------------------------------------------
info "Adding Firebase dependencies (idempotent)..."
flutter pub add firebase_core firebase_auth cloud_firestore
ok "Dependencies present in pubspec.yaml."

# ---- 2. Patch lib/main.dart -------------------------------------------------
info "Patching lib/main.dart (Firebase init + Firestore persistence)..."
python3 - <<'PY'
import sys
MAIN = "lib/main.dart"
src = open(MAIN, encoding="utf-8").read()
orig = src

import_anchor = "import 'package:flutter/services.dart';\n"
fb_imports = (
    "import 'package:firebase_core/firebase_core.dart';\n"
    "import 'package:cloud_firestore/cloud_firestore.dart';\n"
    "import 'firebase_options.dart';\n"
)
if "firebase_options.dart" not in src:
    if import_anchor not in src:
        sys.exit("ANCHOR MISSING (imports): expected \"import 'package:flutter/services.dart';\" in main.dart. No changes made.")
    src = src.replace(import_anchor, import_anchor + fb_imports, 1)

init_anchor = "  WidgetsFlutterBinding.ensureInitialized();\n"
fb_init = (
    "  await Firebase.initializeApp(\n"
    "    options: DefaultFirebaseOptions.currentPlatform,\n"
    "  );\n"
    "  FirebaseFirestore.instance.settings = const Settings(\n"
    "    persistenceEnabled: true,\n"
    "    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,\n"
    "  );\n"
)
if "Firebase.initializeApp" not in src:
    if init_anchor not in src:
        sys.exit("ANCHOR MISSING (init): expected WidgetsFlutterBinding.ensureInitialized(); in main.dart. No changes made.")
    src = src.replace(init_anchor, init_anchor + fb_init, 1)

if src != orig:
    open(MAIN + ".bak", "w", encoding="utf-8").write(orig)
    open(MAIN, "w", encoding="utf-8").write(src)
    print("  patched lib/main.dart (backup: lib/main.dart.bak)")
else:
    print("  lib/main.dart already initialized — no change")
PY
ok "main.dart done."

# ---- 3. Ensure Android minSdk >= 23 ----------------------------------------
info "Checking Android minSdk..."
python3 - <<'PY'
import re, sys
G = "android/app/build.gradle.kts"
try:
    g = open(G, encoding="utf-8").read()
except FileNotFoundError:
    print("  WARN: %s not found. Set minSdk = 23 manually (firebase_auth requires it)." % G); sys.exit(0)
m = re.search(r"minSdk\s*=\s*([A-Za-z0-9_.]+)", g)
if not m:
    print("  WARN: 'minSdk' not found. Ensure minSdk >= 23 manually."); sys.exit(0)
val = m.group(1)
needs = (int(val) < 23) if val.isdigit() else True   # e.g. flutter.minSdkVersion -> force 23
if needs:
    open(G + ".bak", "w", encoding="utf-8").write(g)
    g = g[:m.start(1)] + "23" + g[m.end(1):]
    open(G, "w", encoding="utf-8").write(g)
    print("  patched minSdk (%s -> 23) in build.gradle.kts (backup .bak)" % val)
else:
    print("  minSdk already %s (>=23) — no change" % val)
PY
ok "Android config checked."

# ---- 4. Resolve -------------------------------------------------------------
info "Running flutter pub get..."
flutter pub get
ok "pub get complete."

echo
ok "PIECE 1 complete. Verify the blast radius now:"
echo -e "    ${BLUE}git diff --name-only${NC}"
echo "  Expected ONLY: pubspec.yaml  lib/main.dart  android/app/build.gradle.kts"
echo "  Then run the app — it should look and behave EXACTLY like v4."
echo "  When you've confirmed that, tell me and I'll send Piece 2 (auth layer)."
