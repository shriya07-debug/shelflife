#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6.1 — AUTH FIX v2 (the real one)
# =============================================================================
# Root cause: bottom_nav uses Navigator.pushReplacement to a bare MainShell.
# Since the nav lives inside MainShell (AuthGate's child), the first tab tap
# REPLACES the AuthGate route with a raw MainShell -> AuthGate no longer exists,
# so logout/delete have no gate to fall back to.
#
# Fix: logout/delete explicitly push a FRESH AuthGate on the root navigator and
# clear the stack. A new AuthGate sees the now-signed-out state and shows login.
#
# Patches: lib/view/screens/main/profile_screen.dart (import + 2 handlers)
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v6_1_authfix2.sh .
#   chmod +x v6_1_authfix2.sh && ./v6_1_authfix2.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }

info "Applying auth fix v2..."
python3 - <<'PY'
import sys
p = "lib/view/screens/main/profile_screen.dart"
s = open(p, encoding="utf-8").read()

# import (after the services import added in v5.1b)
imp_old = "import '../../../repo/services.dart';\n"
imp_new = "import '../../../repo/services.dart';\nimport '../auth/auth_gate.dart';\n"

# logout: accept either the authfix (popUntil) OR the Piece-3 (pop + await) form
logout_new = """            onPressed: () async {
              final navigator = Navigator.of(context, rootNavigator: true);
              await profileVM.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },"""
logout_olds = [
"""            onPressed: () async {
              final navigator = Navigator.of(context);
              await profileVM.logout();
              navigator.popUntil((route) => route.isFirst);
            },""",
"""            onPressed: () async {
              Navigator.pop(context);
              await profileVM.logout();
              // AuthGate returns to the login screen automatically.
            },""",
]

delete_new = """            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context, rootNavigator: true);
              final error = await profileVM.deleteAccount();
              if (error != null) {
                Navigator.of(context).pop();
                messenger.showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },"""
delete_olds = [
"""            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final error = await profileVM.deleteAccount();
              if (error != null) {
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              navigator.popUntil((route) => route.isFirst);
            },""",
"""            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final error = await profileVM.deleteAccount();
              navigator.pop();
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text(error)));
              }
              // On success, AuthGate returns to the login screen automatically.
            },""",
]

def pick(cands):
    hits = [c for c in cands if s.count(c) == 1]
    return hits[0] if len(hits) == 1 else None

errors = []
if s.count(imp_old) != 1: errors.append("services import anchor not found (run v5.1b?)")
lo = pick(logout_olds);  do = pick(delete_olds)
if lo is None: errors.append("logout handler anchor not matched")
if do is None: errors.append("delete handler anchor not matched")
if "import '../auth/auth_gate.dart';" in s: errors.append("already applied (auth_gate import present)")

if errors:
    print("ABORT — no changes:")
    for e in errors: print("   - " + e)
    print("If it says an anchor wasn't matched, paste your current logout/delete")
    print("handlers from profile_screen.dart and I'll adjust.")
    sys.exit(1)

open(p + ".bak", "w", encoding="utf-8").write(s)
s = s.replace(imp_old, imp_new, 1).replace(lo, logout_new, 1).replace(do, delete_new, 1)
open(p, "w", encoding="utf-8").write(s)
print("   patched " + p)
PY
ok "Patched."

flutter pub get
echo
ok "v6.1 auth fix v2 complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST: log in -> tap Profile tab -> Log out -> you land on the LOGIN screen."
echo "        Same for Delete Account."
echo
warn "Deeper cause remains: bottom_nav's pushReplacement wipes AuthGate on every"
echo "  tab tap. Logout/delete now work regardless, but the clean long-term fix is"
echo "  a single persistent MainShell with an IndexedStack (ask me for that refactor)."
echo
echo "  Then: git add -A && git commit -m 'v6.1: fix logout/delete redirect (real)' && git tag v6.1-authfix2"
