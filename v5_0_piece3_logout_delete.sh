#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.0 — PIECE 3 of 5: LOGOUT + DELETE ACCOUNT
# =============================================================================
# Wires the two profile actions to Firebase. No new files, no layout changes.
#
# PATCHED (surgical, anchored, backed up to *.bak):
#   lib/viewmodel/profile_vm.dart
#     • logout()        -> awaits authVM.signOut()
#     • deleteAccount() -> deletes the Firebase user, THEN wipes local data;
#                          returns an error string if the auth delete fails
#                          (so data is not destroyed on a failed delete)
#   lib/view/screens/main/profile_screen.dart
#     • logout dialog   -> closes dialog + signs out (AuthGate shows login)
#     • delete dialog   -> deletes, then AuthGate shows login; shows a SnackBar
#                          on failure (e.g. Firebase's "requires recent login")
#     • removes the now-unused LoginScreen import
#
# UNTOUCHED: dialog text, buttons, and all layout — only handler bodies change.
#
# Run from project root:
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_0_piece3_logout_delete.sh .
#   chmod +x v5_0_piece3_logout_delete.sh && ./v5_0_piece3_logout_delete.sh
#
# Rollback: git checkout -- lib/  (or restore the *.bak files)
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/viewmodel/auth_vm.dart" ] || { err "auth_vm.dart missing — run Piece 2 first."; exit 1; }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -n "$(git status --porcelain)" ]; then
  warn "Uncommitted changes present. Commit/stash first for a clean 'git diff'."
  read -r -p "Continue anyway? [y/N] " a; [ "$a" = "y" ] || [ "$a" = "Y" ] || { info "Aborted."; exit 0; }
fi

info "Applying logout/delete patches..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/viewmodel/profile_vm.dart": [
    ("import 'recipe_vm.dart';\n",
     "import 'recipe_vm.dart';\nimport 'auth_vm.dart';\n", 'one'),
    ("""  /// Logout — soft sign-out. No data wipe.
  void logout() {
    // No-op besides UI nav. (Auth integration would clear session here.)
  }""",
     """  /// Logout — signs the user out of Firebase. Local data is left intact.
  Future<void> logout() async {
    await authVM.signOut();
  }""", 'one'),
    ("""  /// Delete account — wipes Hive boxes.
  Future<void> deleteAccount() async {
    await Services.pantry.clear();""",
     """  /// Delete account — removes the Firebase user, then wipes local data.
  /// Returns null on success or a user-facing error message on failure.
  Future<String?> deleteAccount() async {
    final error = await authVM.deleteAccount();
    if (error != null) return error;
    await Services.pantry.clear();""", 'one'),
    ("""    recipeVM.notifyListeners();
    notifyListeners();
  }

  Future<void> resetDemoData() async {""",
     """    recipeVM.notifyListeners();
    notifyListeners();
    return null;
  }

  Future<void> resetDemoData() async {""", 'one'),
  ],
  "lib/view/screens/main/profile_screen.dart": [
    ("import '../auth/login_screen.dart';\n", "", 'one'),
    ("""            onPressed: () {
              profileVM.logout();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },""",
     """            onPressed: () async {
              Navigator.pop(context);
              await profileVM.logout();
              // AuthGate returns to the login screen automatically.
            },""", 'one'),
    ("""            onPressed: () async {
              await profileVM.deleteAccount();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
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
            },""", 'one'),
  ],
}

fail = []
cache = {}
for path, edits in EDITS.items():
    try:
        s = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        fail.append("MISSING FILE: " + path); continue
    cache[path] = s
    for i, (old, new, mode) in enumerate(edits):
        c = s.count(old)
        if (mode == 'all' and c == 0) or (mode == 'one' and c != 1):
            fail.append("%s: anchor #%d found %dx (need %s)" %
                        (path, i, c, "1" if mode == 'one' else ">=1"))

if fail:
    print("ABORT — no files changed. Anchor problems:")
    for f in fail:
        print("   - " + f)
    print("\nIf you already ran Piece 3, these anchors are gone (already patched).")
    sys.exit(1)

for path, edits in EDITS.items():
    s = cache[path]
    open(path + ".bak", "w", encoding="utf-8").write(s)
    for old, new, mode in edits:
        s = s.replace(old, new) if mode == 'all' else s.replace(old, new, 1)
    open(path, "w", encoding="utf-8").write(s)
    print("   patched " + path + "  (backup: " + path + ".bak)")
PY
ok "Patches applied."

info "flutter pub get..."
flutter pub get
echo
warn "Run:  flutter analyze   (expect 0 errors)"
echo
ok "PIECE 3 complete. Verify + test:"
echo -e "    ${BLUE}git diff --name-only${NC}   -> profile_vm.dart + profile_screen.dart ONLY"
echo "  TEST:"
echo "   1. Log in, go to Profile -> Log out  -> returns to login screen."
echo "   2. Log back in -> Profile -> Delete Account -> confirm."
echo "      (If it says 'sign in again to complete', that's Firebase's recent-login"
echo "       rule — log out/in and retry; full re-auth flow can come later.)"
echo "   3. Check Firebase Console > Authentication: deleted user is gone."
echo
echo "  Then: git add . && git commit -m 'v5.0 piece 3: logout + delete' && git tag v5.0-p3"
echo "  Tell me when done and I'll send Piece 4 (per-user Firestore repos)."
