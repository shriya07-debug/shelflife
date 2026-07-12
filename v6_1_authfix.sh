#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6.1 — AUTH FIX: logout / delete now return to the login screen
# =============================================================================
# Bottom-nav taps PUSH new MainShell routes, so the Profile tab sits on a
# pushed route above AuthGate. On logout/delete, AuthGate (underneath) flips to
# the login screen but the pushed MainShell covers it. Fix: popUntil isFirst
# after signing out / deleting, which clears those routes down to the gate.
# (Harmless no-op if nothing is pushed.)
#
# Patches: lib/view/screens/main/profile_screen.dart (two handlers)
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v6_1_authfix.sh .
#   chmod +x v6_1_authfix.sh && ./v6_1_authfix.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }

info "Patching logout/delete handlers..."
python3 - <<'PY'
import sys
p = "lib/view/screens/main/profile_screen.dart"
s = open(p, encoding="utf-8").read()
E = [
  ("""            onPressed: () async {
              Navigator.pop(context);
              await profileVM.logout();
              // AuthGate returns to the login screen automatically.
            },""",
   """            onPressed: () async {
              final navigator = Navigator.of(context);
              await profileVM.logout();
              navigator.popUntil((route) => route.isFirst);
            },"""),
  ("""            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final error = await profileVM.deleteAccount();
              navigator.pop();
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text(error)));
              }
              // On success, AuthGate returns to the login screen automatically.
            },""",
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
            },"""),
]
fail = [i for i, (o, _) in enumerate(E) if s.count(o) != 1]
if fail:
    print("ABORT: anchors %s not uniquely found (already applied?)." % fail); sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in E:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("   patched " + p)
PY
ok "Patched."

flutter pub get
echo
ok "v6.1 auth fix complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Log in -> tap around the bottom tabs -> Profile -> Log out -> confirm:"
echo "      you land back on the LOGIN screen."
echo "   2. Log in -> Profile -> Delete Account -> confirm: back to login, user gone"
echo "      from Firebase Auth. (Wrong-recent-login error still shows a message.)"
echo
echo "  Then: git add -A && git commit -m 'v6.1: fix logout/delete redirect' && git tag v6.1-authfix"
