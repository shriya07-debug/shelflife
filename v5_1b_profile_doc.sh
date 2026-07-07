#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.1b — PROFILE DOC (dietary/allergy prefs) + DELETION CLEANUP
# =============================================================================
# NEW:   lib/repo/profile_repo.dart, profile_repo_firebase_impl.dart
# PATCH: services.dart (bind profile), signup_draft.dart (+ dietary/allergies),
#        signup_step2 (stash dietary), signup_step3 (stash allergies + write
#        profile), profile_screen (show real prefs, "None set" when empty),
#        profile_vm (delete profile + meta on account deletion)
#
# Profile doc lives at users/{uid}/profile/main. Covered by existing rules.
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_1b_profile_doc.sh .
#   chmod +x v5_1b_profile_doc.sh && ./v5_1b_profile_doc.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/repo/known_items_repo.dart" ] || { err "Run v5.1a-autocomplete first."; exit 1; }

info "Writing profile repo..."
cat > lib/repo/profile_repo.dart <<'DART'
class UserProfile {
  final String name;
  final List<String> dietary;
  final List<String> allergies;
  const UserProfile({
    this.name = '',
    this.dietary = const [],
    this.allergies = const [],
  });
}

abstract class ProfileRepo {
  Future<void> init();
  UserProfile get profile;
  Future<void> save(UserProfile profile);
}
DART

cat > lib/repo/profile_repo_firebase_impl.dart <<'DART'
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_repo.dart';

/// Firestore-backed profile at users/{uid}/profile/main.
class ProfileRepoFirebaseImpl implements ProfileRepo {
  ProfileRepoFirebaseImpl(this.uid);
  final String uid;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profile')
      .doc('main');

  UserProfile _cache = const UserProfile();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  static UserProfile _fromMap(Map<String, dynamic>? m) {
    if (m == null) return const UserProfile();
    return UserProfile(
      name: (m['name'] as String?) ?? '',
      dietary: ((m['dietary'] as List?) ?? const []).map((e) => '$e').toList(),
      allergies:
          ((m['allergies'] as List?) ?? const []).map((e) => '$e').toList(),
    );
  }

  static Map<String, dynamic> _toMap(UserProfile p) =>
      {'name': p.name, 'dietary': p.dietary, 'allergies': p.allergies};

  @override
  Future<void> init() async {
    _cache = _fromMap((await _doc.get()).data());
    _sub = _doc.snapshots().listen(
      (snap) => _cache = _fromMap(snap.data()),
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  UserProfile get profile => _cache;

  @override
  Future<void> save(UserProfile profile) async {
    _cache = profile;
    await _doc.set(_toMap(profile));
  }

  /// Write a profile for [uid] without needing a bound instance (used at signup,
  /// before the service locator has bound the new user).
  static Future<void> writeFor(String uid, UserProfile p) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('profile')
      .doc('main')
      .set(_toMap(p));

  /// Delete the profile + first-launch flag for [uid] (account deletion).
  static Future<void> purgeFor(String uid) async {
    final u = FirebaseFirestore.instance.collection('users').doc(uid);
    await u.collection('meta').doc('flags').delete();
    await u.collection('profile').doc('main').delete();
  }
}
DART
ok "profile repo written."

info "Extending signup_draft..."
cat > lib/view/screens/onboarding/signup_draft.dart <<'DART'
/// Carries signup form data from step 1 through to account creation in step 3.
class SignupDraft {
  SignupDraft._();
  static final SignupDraft i = SignupDraft._();

  String name = '';
  String email = '';
  String password = '';
  String birthday = '';
  List<String> dietary = [];
  List<String> allergies = [];

  void clear() {
    name = '';
    email = '';
    password = '';
    birthday = '';
    dietary = [];
    allergies = [];
  }
}
DART
ok "signup_draft extended."

info "Applying patches (all-or-nothing)..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/repo/services.dart": [
    ("import 'known_items_repo_firebase_impl.dart';\n",
     "import 'known_items_repo_firebase_impl.dart';\nimport 'profile_repo.dart';\nimport 'profile_repo_firebase_impl.dart';\n"),
    ("  static KnownItemsRepoFirebaseImpl? _knownItems;\n",
     "  static KnownItemsRepoFirebaseImpl? _knownItems;\n  static ProfileRepoFirebaseImpl? _profile;\n"),
    ("  static KnownItemsRepo get knownItems => _knownItems!;\n",
     "  static KnownItemsRepo get knownItems => _knownItems!;\n  static ProfileRepo get profile => _profile!;\n"),
    ("    final k = KnownItemsRepoFirebaseImpl();\n    await Future.wait([p.init(), s.init(), f.init(), k.init()]);\n",
     "    final k = KnownItemsRepoFirebaseImpl();\n    final pr = ProfileRepoFirebaseImpl(uid);\n    await Future.wait([p.init(), s.init(), f.init(), k.init(), pr.init()]);\n"),
    ("    _knownItems = k;\n", "    _knownItems = k;\n    _profile = pr;\n"),
    ("    _knownItems?.dispose();\n", "    _knownItems?.dispose();\n    _profile?.dispose();\n"),
    ("    _knownItems = null;\n", "    _knownItems = null;\n    _profile = null;\n"),
  ],
  "lib/view/screens/onboarding/signup_step2_screen.dart": [
    ("import 'signup_step3_screen.dart';\n",
     "import 'signup_step3_screen.dart';\nimport 'signup_draft.dart';\n"),
    ("""                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep3Screen()),
                      ),""",
     """                      onPressed: () {
                        SignupDraft.i.dietary = _selected.toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupStep3Screen()),
                        );
                      },"""),
  ],
  "lib/view/screens/onboarding/signup_step3_screen.dart": [
    ("import 'signup_draft.dart';\n",
     "import 'signup_draft.dart';\nimport '../../../repo/profile_repo.dart';\nimport '../../../repo/profile_repo_firebase_impl.dart';\n"),
    ("""                        final d = SignupDraft.i;
                        if (d.email.isEmpty || d.password.isEmpty) {""",
     """                        final d = SignupDraft.i;
                        d.allergies = _selected.toList();
                        if (d.email.isEmpty || d.password.isEmpty) {"""),
    ("""                        SignupDraft.i.clear();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);""",
     """                        final uid = authVM.currentUser?.uid;
                        if (uid != null) {
                          await ProfileRepoFirebaseImpl.writeFor(
                            uid,
                            UserProfile(
                              name: d.name,
                              dietary: d.dietary,
                              allergies: d.allergies,
                            ),
                          );
                        }
                        SignupDraft.i.clear();
                        if (!context.mounted) return;
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);"""),
  ],
  "lib/view/screens/main/profile_screen.dart": [
    ("import '../../../viewmodel/auth_vm.dart';\n",
     "import '../../../viewmodel/auth_vm.dart';\nimport '../../../repo/services.dart';\n"),
    ("""            children: [
              _pill('Vegetarian', AppColors.primaryLight,
                  AppColors.primaryDark),
              _pill('Organic', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Gluten-Free', const Color(0xFFFFF3E0),
                  const Color(0xFFB45309)),
              _pill('+ Add Focus', AppColors.chipBg(context),
                  AppColors.textPri(context)),
            ],""",
     "            children: _dietaryPills(context),"),
    ("""          const SizedBox(height: 12),
          _allergyRow(context, 'Peanuts & Tree Nuts'),
          const SizedBox(height: 8),
          _allergyRow(context, 'Shellfish'),""",
     """          const SizedBox(height: 12),
          ..._allergyRows(context),"""),
    ("  Widget _pill(String label, Color bg, Color fg) {",
     """  List<Widget> _dietaryPills(BuildContext context) {
    final prefs = Services.profile.profile.dietary;
    if (prefs.isEmpty) {
      return [
        _pill('None set', AppColors.chipBg(context),
            AppColors.textPri(context)),
      ];
    }
    return prefs
        .map((p) => _pill(p, AppColors.primaryLight, AppColors.primaryDark))
        .toList();
  }

  List<Widget> _allergyRows(BuildContext context) {
    final list = Services.profile.profile.allergies;
    if (list.isEmpty) {
      return [
        Text('None set',
            style: TextStyle(color: AppColors.textSec(context))),
      ];
    }
    final out = <Widget>[];
    for (var i = 0; i < list.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 8));
      out.add(_allergyRow(context, list[i]));
    }
    return out;
  }

  Widget _pill(String label, Color bg, Color fg) {"""),
  ],
  "lib/viewmodel/profile_vm.dart": [
    ("import 'auth_vm.dart';\n",
     "import 'auth_vm.dart';\nimport '../repo/profile_repo_firebase_impl.dart';\n"),
    ("""    await Services.favorites.clear();
    final error = await authVM.deleteAccount();""",
     """    await Services.favorites.clear();
    final uid = authVM.currentUser?.uid;
    if (uid != null) await ProfileRepoFirebaseImpl.purgeFor(uid);
    final error = await authVM.deleteAccount();"""),
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
    print("\n(If already applied, anchors are gone — expected.)")
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
ok "v5.1b complete — and that's all of v5.1."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Register: pick some dietary prefs (step 2) + allergies (step 3)."
echo "      Profile screen shows exactly those (not the old hardcoded ones)."
echo "   2. Firestore: users/<uid>/profile/main has name + dietary + allergies."
echo "   3. Register skipping prefs -> Profile shows 'None set'."
echo "   4. Delete account -> users/<uid> profile + meta docs are removed too."
echo
echo "  Then: git add -A && git commit -m 'v5.1b: profile doc' && git tag v5.1"
echo "  v5.1 done. Next up: v6 barcode scan-to-add."
