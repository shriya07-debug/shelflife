#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.1b — FORGOT PASSWORD  (part 1 of the identity cluster)
# =============================================================================
# Adds a password-reset screen and makes the login "Forgot Password?" tappable.
# Uses authVM.sendPasswordReset (already added in Piece 2).
#
# NEW:   lib/view/screens/auth/forgot_password_screen.dart
# PATCH: login_screen.dart (import + wrap the Forgot Password text)
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_1b_forgot_password.sh .
#   chmod +x v5_1b_forgot_password.sh && ./v5_1b_forgot_password.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/viewmodel/auth_vm.dart" ] || { err "Run v5.0 (Piece 2) first."; exit 1; }

info "Writing forgot_password_screen.dart..."
cat > lib/view/screens/auth/forgot_password_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email.');
      return;
    }
    setState(() => _busy = true);
    final error = await authVM.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = error == null;
    });
    if (error != null) _snack(error);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        title: Text('Reset Password',
            style: TextStyle(color: AppColors.textPri(context))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sent
                  ? 'If an account exists for that email, a reset link is on its way. Check your inbox.'
                  : "Enter your account email and we'll send you a password reset link.",
              style: TextStyle(color: AppColors.textSec(context), fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
                hintText: 'you@example.com',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _send,
                child: Text(_sent ? 'Resend link' : 'Send reset link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART
ok "forgot_password_screen.dart written."

info "Wiring the login Forgot Password link..."
python3 - <<'PY'
import sys
p = "lib/view/screens/auth/login_screen.dart"
s = open(p, encoding="utf-8").read()
edits = [
  ("import '../onboarding/signup_step1_screen.dart';\n",
   "import '../onboarding/signup_step1_screen.dart';\nimport 'forgot_password_screen.dart';\n"),
  ("""                        const Text('Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),""",
   """                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordScreen()),
                          ),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),"""),
]
fail = [i for i, (o, _) in enumerate(edits) if s.count(o) != 1]
if fail:
    print("ABORT: anchors %s not uniquely found. No change." % fail); sys.exit(1)
open(p + ".bak", "w", encoding="utf-8").write(s)
for o, n in edits:
    s = s.replace(o, n, 1)
open(p, "w", encoding="utf-8").write(s)
print("   patched " + p)
PY
ok "login_screen.dart patched."

flutter pub get
echo
ok "v5.1b-forgot complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Login screen -> tap 'Forgot Password?' -> reset screen opens."
echo "   2. Enter a REGISTERED email -> 'Send reset link' -> confirmation message,"
echo "      and a reset email arrives (check spam)."
echo "   3. Enter a random email -> still shows the same neutral message"
echo "      (Firebase doesn't reveal whether an account exists)."
echo
echo "  Then: git add -A && git commit -m 'v5.1b: forgot password' && git tag v5.1b-forgot"
echo "  Next: the profile-doc piece (dietary/allergy prefs + deletion cleanup)."
