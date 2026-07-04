#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.0 — PIECE 2 of (now) 5: AUTH  (sign-in + sign-up path)
# =============================================================================
# Adds real Firebase email/password auth without changing any layout.
#
# NEW files (nothing to drift):
#   lib/repo/auth_repo.dart              (interface + AuthUser + AuthException)
#   lib/repo/auth_repo_impl.dart         (FirebaseAuth implementation)
#   lib/viewmodel/auth_vm.dart           (global authVM, mirrors your VM pattern)
#   lib/view/screens/auth/auth_gate.dart (routes logged-out vs logged-in)
#   lib/view/screens/onboarding/signup_draft.dart (carries step1 -> step3 data)
#
# PATCHED files (surgical, anchored, backed up to *.bak):
#   splash_screen.dart        -> navigates to AuthGate instead of LoginScreen
#   login_screen.dart         -> real sign-in; social buttons show "coming soon"
#   signup_step1_screen.dart  -> stashes name/email/password/birthday
#   signup_step3_screen.dart  -> creates the Firebase account on finish
#
# UNTOUCHED: every theme/color/size/widget file and all screen LAYOUTS.
# After running, `git diff --name-only` should list ONLY the 4 files above
# (plus 4 new files under untracked). If anything else appears, STOP.
#
# NOTE: Data is still local Hive in this piece; per-user cloud sync is Piece 5.
# So right after this, two different accounts still see the same local data —
# that's expected and gets fixed when repos are swapped.
#
# Run from project root:
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   chmod +x v5_0_piece2_auth.sh && ./v5_0_piece2_auth.sh
#
# Rollback:  git checkout -- lib/ ; git clean -fd lib/view/screens/auth lib/repo
#        or: restore each *.bak sibling.
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/repo/services.dart" ] || { err "lib/repo/services.dart missing — run this on your v4 tree."; exit 1; }
grep -q "firebase_auth" pubspec.yaml || { err "firebase_auth not in pubspec — run Piece 1 first."; exit 1; }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -n "$(git status --porcelain)" ]; then
  warn "Uncommitted changes present. Commit/stash first for a clean 'git diff'."
  read -r -p "Continue anyway? [y/N] " a; [ "$a" = "y" ] || [ "$a" = "Y" ] || { info "Aborted."; exit 0; }
fi

mkdir -p lib/view/screens/auth lib/view/screens/onboarding lib/viewmodel lib/repo

# =============================================================================
# NEW FILES
# =============================================================================
info "Writing auth repository interface..."
cat > lib/repo/auth_repo.dart <<'DART'
/// Framework-agnostic snapshot of the signed-in user, so the UI/VM layer
/// never has to import FirebaseAuth directly.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  const AuthUser({required this.uid, this.email, this.displayName});
}

/// Thrown for expected auth failures. [message] is safe to show to users.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

abstract class AuthRepo {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> sendPasswordReset(String email);
}
DART
ok "auth_repo.dart"

info "Writing Firebase auth implementation..."
cat > lib/repo/auth_repo_impl.dart <<'DART'
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthUser? _map(User? u) => u == null
      ? null
      : AuthUser(uid: u.uid, email: u.email, displayName: u.displayName);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final n = name.trim();
      if (n.isNotEmpty) {
        await cred.user?.updateDisplayName(n);
        await cred.user?.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      await u.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e));
    }
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
DART
ok "auth_repo_impl.dart"

info "Writing auth view-model..."
cat > lib/viewmodel/auth_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../repo/auth_repo.dart';
import '../repo/auth_repo_impl.dart';

/// Global auth view-model, matching the app's existing `final xVM = XVM();`
/// convention. Methods return null on success or a user-facing error string.
final authVM = AuthVM();

class AuthVM extends ChangeNotifier {
  final AuthRepo _repo = AuthRepoImpl();

  bool busy = false;

  Stream<AuthUser?> get authState => _repo.authStateChanges();
  AuthUser? get currentUser => _repo.currentUser;

  Future<String?> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email.trim(), password: password));

  Future<String?> signUp(String email, String password, String name) => _run(
      () => _repo.signUp(email: email.trim(), password: password, name: name));

  Future<void> signOut() => _repo.signOut();

  Future<String?> deleteAccount() => _run(() => _repo.deleteAccount());

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<String?> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
DART
ok "auth_vm.dart"

info "Writing AuthGate..."
cat > lib/view/screens/auth/auth_gate.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../repo/auth_repo.dart';
import '../../../viewmodel/auth_vm.dart';
import 'login_screen.dart';
import '../main/main_shell.dart';

/// Watches Firebase auth state and shows either the login flow or the main
/// app. Replaces the old direct navigation from splash to LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authVM.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const MainShell();
      },
    );
  }
}
DART
ok "auth_gate.dart"

info "Writing signup draft carrier..."
cat > lib/view/screens/onboarding/signup_draft.dart <<'DART'
/// Carries signup form data from step 1 to the account-creation call in
/// step 3. Intentionally tiny; cleared once the account is created.
class SignupDraft {
  SignupDraft._();
  static final SignupDraft i = SignupDraft._();

  String name = '';
  String email = '';
  String password = '';
  String birthday = '';

  void clear() {
    name = '';
    email = '';
    password = '';
    birthday = '';
  }
}
DART
ok "signup_draft.dart"

# =============================================================================
# SURGICAL PATCHES (all-or-nothing: validates every anchor before writing)
# =============================================================================
info "Applying anchored patches to splash / login / signup..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/view/screens/misc/splash_screen.dart": [
    ("import '../auth/login_screen.dart';\n",
     "import '../auth/auth_gate.dart';\n", 'one'),
    ("builder: (_) => const LoginScreen()),",
     "builder: (_) => const AuthGate()),", 'one'),
  ],
  "lib/view/screens/auth/login_screen.dart": [
    ("import '../main/main_shell.dart';\n",
     "import '../../../viewmodel/auth_vm.dart';\n", 'one'),
    ("  bool _obscure = true;\n",
     "  bool _obscure = true;\n"
     "  bool _busy = false;\n"
     "  final _emailCtrl = TextEditingController();\n"
     "  final _passCtrl = TextEditingController();\n\n"
     "  @override\n"
     "  void dispose() {\n"
     "    _emailCtrl.dispose();\n"
     "    _passCtrl.dispose();\n"
     "    super.dispose();\n"
     "  }\n", 'one'),
    ("""  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }""",
     """  Future<void> _login() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _snack('Please enter your email and password.');
      return;
    }
    setState(() => _busy = true);
    final error = await authVM.signIn(email, pass);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _snack(error);
    // On success, AuthGate swaps to the main app automatically.
  }

  void _soon() => _snack('Social sign-in is coming soon. Use email for now.');

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }""", 'one'),
    ("""                    const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your email',
                      ),
                    ),""",
     """                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your email',
                      ),
                    ),""", 'one'),
    ("""                    TextField(
                      obscureText: _obscure,""",
     """                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,""", 'one'),
    (".icon(\n                      onPressed: _login,",
     ".icon(\n                      onPressed: _soon,", 'all'),
  ],
  "lib/view/screens/onboarding/signup_step1_screen.dart": [
    ("import 'signup_step2_screen.dart';\n",
     "import 'signup_step2_screen.dart';\nimport 'signup_draft.dart';\n", 'one'),
    ("""                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep2Screen()),
                      ),""",
     """                      onPressed: () {
                        SignupDraft.i
                          ..name = _nameCtrl.text.trim()
                          ..email = _emailCtrl.text.trim()
                          ..password = _passCtrl.text
                          ..birthday = _bdayCtrl.text.trim();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupStep2Screen()),
                        );
                      },""", 'one'),
  ],
  "lib/view/screens/onboarding/signup_step3_screen.dart": [
    ("import '../main/main_shell.dart';\n",
     "import '../../../viewmodel/auth_vm.dart';\nimport 'signup_draft.dart';\n",
     'one'),
    ("""                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (_) => false,
                      ),""",
     """                      onPressed: () async {
                        final d = SignupDraft.i;
                        if (d.email.isEmpty || d.password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please restart signup from step 1.')),
                          );
                          return;
                        }
                        final error =
                            await authVM.signUp(d.email, d.password, d.name);
                        if (!context.mounted) return;
                        if (error != null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }
                        SignupDraft.i.clear();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },""", 'one'),
  ],
}

# ---- Pass 1: validate ALL anchors, write nothing ----
fail = []
cache = {}
for path, edits in EDITS.items():
    try:
        s = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        fail.append("MISSING FILE: " + path)
        continue
    cache[path] = s
    for i, (old, new, mode) in enumerate(edits):
        c = s.count(old)
        if mode == 'all':
            if c == 0:
                fail.append("%s: anchor #%d not found" % (path, i))
        else:
            if c != 1:
                fail.append("%s: anchor #%d found %dx (need exactly 1)" % (path, i, c))

if fail:
    print("ABORT — no files changed. Anchor problems:")
    for f in fail:
        print("   - " + f)
    print("\nIf you have already run Piece 2, these anchors are gone because the")
    print("files are already patched. In that case this abort is expected.")
    sys.exit(1)

# ---- Pass 2: apply + back up ----
for path, edits in EDITS.items():
    s = cache[path]
    open(path + ".bak", "w", encoding="utf-8").write(s)
    for old, new, mode in edits:
        s = s.replace(old, new) if mode == 'all' else s.replace(old, new, 1)
    open(path, "w", encoding="utf-8").write(s)
    print("   patched " + path + "  (backup: " + path + ".bak)")
PY
ok "Patches applied."

# =============================================================================
info "Running flutter pub get + analyze..."
flutter pub get
echo
warn "Now run:  flutter analyze   (expect 0 errors; harmless 'unused' infos are fine)"

echo
ok "PIECE 2 complete. Verify:"
echo -e "    ${BLUE}git diff --name-only${NC}   (modified: splash/login/signup_step1/signup_step3 only)"
echo -e "    ${BLUE}git status${NC}             (new: auth_repo, auth_repo_impl, auth_vm, auth_gate, signup_draft)"
echo "  Nothing under theme/, widgets/, or any other screen should appear."
echo
echo "  TEST FLOW:"
echo "   1. flutter run"
echo "   2. Register a new account (step 1 -> 3) -> should land in the app."
echo "   3. Hot-restart, then Login with those same credentials."
echo "   4. In Firebase Console > Authentication, confirm the user exists."
echo
echo "  When that works, tell me and I'll send Piece 3 (logout + delete account)."
