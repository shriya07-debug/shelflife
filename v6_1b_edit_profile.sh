#!/usr/bin/env bash
# =============================================================================
# ShelfLife v6.1b — SYNC PASS: Edit Profile becomes real
# =============================================================================
# Edit Profile now loads your real data and actually saves it:
#   name  -> profile doc + auth display name
#   phone -> profile doc (new field)
#   bio   -> profile doc (new field)
#   email -> read-only (it's your account email)
#   password -> real change with re-authentication (needs current password)
# Dietary/allergy prefs are preserved on save.
#
# Touches: profile_repo(+impl) [phone/bio], auth_repo(+impl)+auth_vm
#   [updateDisplayName/changePassword], edit_profile_screen.
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v6_1b_edit_profile.sh .
#   chmod +x v6_1b_edit_profile.sh && ./v6_1b_edit_profile.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/repo/profile_repo.dart" ] || { err "Run v5.1b first."; exit 1; }

info "Applying v6.1b patches (all-or-nothing)..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/repo/profile_repo.dart": [
    ("  final List<String> allergies;\n",
     "  final List<String> allergies;\n  final String phone;\n  final String bio;\n"),
    ("    this.allergies = const [],\n",
     "    this.allergies = const [],\n    this.phone = '',\n    this.bio = '',\n"),
  ],
  "lib/repo/profile_repo_firebase_impl.dart": [
    ("      allergies:\n          ((m['allergies'] as List?) ?? const []).map((e) => '$e').toList(),\n",
     "      allergies:\n          ((m['allergies'] as List?) ?? const []).map((e) => '$e').toList(),\n      phone: (m['phone'] as String?) ?? '',\n      bio: (m['bio'] as String?) ?? '',\n"),
    ("      {'name': p.name, 'dietary': p.dietary, 'allergies': p.allergies};\n",
     "      {'name': p.name, 'dietary': p.dietary, 'allergies': p.allergies, 'phone': p.phone, 'bio': p.bio};\n"),
  ],
  "lib/repo/auth_repo.dart": [
    ("  Future<void> signOut();\n",
     "  Future<void> signOut();\n  Future<void> updateDisplayName(String name);\n  Future<void> changePassword(String currentPassword, String newPassword);\n"),
  ],
  "lib/repo/auth_repo_impl.dart": [
    ("  @override\n  Future<void> signOut() => _auth.signOut();\n",
     "  @override\n  Future<void> signOut() => _auth.signOut();\n\n"
     "  @override\n  Future<void> updateDisplayName(String name) async {\n"
     "    final u = _auth.currentUser;\n    if (u == null) return;\n    try {\n"
     "      await u.updateDisplayName(name.trim());\n      await u.reload();\n"
     "    } on FirebaseAuthException catch (e) {\n      throw AuthException(_friendly(e));\n    }\n  }\n\n"
     "  @override\n  Future<void> changePassword(String currentPassword, String newPassword) async {\n"
     "    final u = _auth.currentUser;\n    final email = u?.email;\n"
     "    if (u == null || email == null) throw AuthException('Not signed in.');\n    try {\n"
     "      final cred = EmailAuthProvider.credential(\n          email: email, password: currentPassword);\n"
     "      await u.reauthenticateWithCredential(cred);\n      await u.updatePassword(newPassword);\n"
     "    } on FirebaseAuthException catch (e) {\n      throw AuthException(_friendly(e));\n    }\n  }\n"),
  ],
  "lib/viewmodel/auth_vm.dart": [
    ("  Future<void> signOut() => _repo.signOut();\n",
     "  Future<void> signOut() => _repo.signOut();\n\n"
     "  Future<String?> updateDisplayName(String name) =>\n      _run(() => _repo.updateDisplayName(name));\n\n"
     "  Future<String?> changePassword(String current, String next) =>\n      _run(() => _repo.changePassword(current, next));\n"),
  ],
  "lib/view/screens/misc/edit_profile_screen.dart": [
    ("import '../../../constants/app_strings.dart';\n", ""),
    ("import '../../widgets/app_logo.dart';\n",
     "import '../../widgets/app_logo.dart';\nimport '../../../repo/services.dart';\nimport '../../../repo/profile_repo.dart';\nimport '../../../viewmodel/auth_vm.dart';\nimport '../../../viewmodel/profile_vm.dart';\n"),
    ("      TextEditingController(text: AppStrings.userName);\n",
     "      TextEditingController(text: Services.profile.profile.name);\n"),
    ("      TextEditingController(text: AppStrings.userEmail);\n",
     "      TextEditingController(text: authVM.currentUser?.email ?? '');\n"),
    ("  final _phoneCtrl = TextEditingController(text: '+977 98XXXXXXXX');\n",
     "  final _phoneCtrl = TextEditingController(text: Services.profile.profile.phone);\n"),
    ("      TextEditingController(text: 'Trying to waste less and cook more.');\n",
     "      TextEditingController(text: Services.profile.profile.bio);\n"),
    ("  bool _newObscure = true;\n",
     "  bool _newObscure = true;\n  final _currentPassCtrl = TextEditingController();\n  final _newPassCtrl = TextEditingController();\n"),
    ("    _bioCtrl.dispose();\n",
     "    _bioCtrl.dispose();\n    _currentPassCtrl.dispose();\n    _newPassCtrl.dispose();\n"),
    ("      {TextInputType type = TextInputType.text, int maxLines = 1}) {\n",
     "      {TextInputType type = TextInputType.text,\n      int maxLines = 1,\n      bool readOnly = false}) {\n"),
    ("      controller: c,\n      keyboardType: type,\n",
     "      controller: c,\n      readOnly: readOnly,\n      keyboardType: type,\n"),
    ("                _field('Email Address', _emailCtrl, Icons.email_outlined,\n                    type: TextInputType.emailAddress),",
     "                _field('Email Address', _emailCtrl, Icons.email_outlined,\n                    type: TextInputType.emailAddress, readOnly: true),"),
    ("                TextField(\n                  obscureText: _currentObscure,\n",
     "                TextField(\n                  controller: _currentPassCtrl,\n                  obscureText: _currentObscure,\n"),
    ("                TextField(\n                  obscureText: _newObscure,\n",
     "                TextField(\n                  controller: _newPassCtrl,\n                  obscureText: _newObscure,\n"),
    ("""            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile saved.')),
              );
              Navigator.pop(context);
            },""",
     """            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final name = _nameCtrl.text.trim();
              final current = Services.profile.profile;
              await Services.profile.save(UserProfile(
                name: name.isEmpty ? current.name : name,
                dietary: current.dietary,
                allergies: current.allergies,
                phone: _phoneCtrl.text.trim(),
                bio: _bioCtrl.text.trim(),
              ));
              if (name.isNotEmpty) await authVM.updateDisplayName(name);
              final newPass = _newPassCtrl.text;
              if (newPass.isNotEmpty) {
                final err =
                    await authVM.changePassword(_currentPassCtrl.text, newPass);
                if (err != null) {
                  messenger.showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
              }
              profileVM.notifyListeners();
              messenger
                  .showSnackBar(const SnackBar(content: Text('Profile saved.')));
              navigator.pop();
            },"""),
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
ok "v6.1b complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Profile -> Edit Profile Details: fields show your REAL name/email/phone/bio."
echo "   2. Change name/phone/bio -> Save Changes -> reopen: values persist;"
echo "      Profile header shows the new name; Firestore users/<uid>/profile updated."
echo "   3. Email field is read-only (it's your account email)."
echo "   4. Change Password: enter current + new -> Save -> log out, log in with new one."
echo "      (Wrong current password -> clear error; no silent fake-save.)"
echo
echo "  Then: git add -A && git commit -m 'v6.1b: edit profile real save' && git tag v6.1b"
echo "  Next: v6.1c (persist the Push Notifications toggle)."
