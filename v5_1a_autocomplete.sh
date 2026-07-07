#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.1a — ITEM NAME AUTOCOMPLETE  (part 2 of "Smart add")
# =============================================================================
# A shared Firestore 'known_items' collection that grows as users add items.
# Typing in the Add-Item name field suggests matches; tapping one fills the
# name AND sets the category. Case-insensitive (Milk == milk).
#
# NEW:   lib/repo/known_items_repo.dart, known_items_repo_firebase_impl.dart
# PATCH: services.dart (bind known_items), pantry_vm.dart (upsert on add),
#        add_item_screen.dart (suggestions + category auto-set), firestore.rules
#
# NOTE: 'known_items' is SHARED across users (foundation for the v6 scan cache).
# You MUST re-publish firestore.rules after this (adds a known_items rule).
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_1a_autocomplete.sh .
#   chmod +x v5_1a_autocomplete.sh && ./v5_1a_autocomplete.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
[ -f "lib/repo/pantry_repo_firebase_impl.dart" ] || { err "Run v5.0 (Piece 4) first."; exit 1; }
grep -q "imageUrl" lib/model/pantry_item.dart || { err "Run v5.1a-image first."; exit 1; }

info "Writing known_items repo..."
cat > lib/repo/known_items_repo.dart <<'DART'
/// A globally-shared item the app has seen before, used for name autocomplete
/// (and, later, the barcode-scan cache).
class KnownItem {
  final String name;
  final String category;
  const KnownItem({required this.name, required this.category});
}

abstract class KnownItemsRepo {
  Future<void> init();
  List<KnownItem> getAll();
  Future<void> remember(String name, String category);
}
DART

cat > lib/repo/known_items_repo_firebase_impl.dart <<'DART'
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'known_items_repo.dart';

/// SHARED across all users: Firestore collection 'known_items'.
/// Doc id is the lower-cased name, so 'Milk' and 'milk' merge into one.
class KnownItemsRepoFirebaseImpl implements KnownItemsRepo {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('known_items');

  final Map<String, KnownItem> _cache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  String _key(String name) => name.trim().toLowerCase().replaceAll('/', '_');

  void _apply(QuerySnapshot<Map<String, dynamic>> snap) {
    _cache
      ..clear()
      ..addEntries(snap.docs.map((d) {
        final m = d.data();
        return MapEntry(
          d.id,
          KnownItem(
            name: (m['name'] as String?) ?? d.id,
            category: (m['category'] as String?) ?? 'Other',
          ),
        );
      }));
  }

  @override
  Future<void> init() async {
    _apply(await _col.get());
    _sub = _col.snapshots().listen(_apply, onError: (_) {});
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  List<KnownItem> getAll() => _cache.values.toList();

  @override
  Future<void> remember(String name, String category) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final key = _key(n);
    if (key.isEmpty) return;
    _cache[key] = KnownItem(name: n, category: category);
    await _col.doc(key).set({'name': n, 'category': category});
  }
}
DART
ok "known_items repo written."

info "Patching services / pantry_vm / add_item_screen (all-or-nothing)..."
python3 - <<'PY'
import sys

SUGGEST = '''  Widget _nameSuggestions(BuildContext context) {
    final q = _nameCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return const SizedBox.shrink();
    final matches = Services.knownItems
        .getAll()
        .where((k) => k.name.toLowerCase().contains(q) &&
            k.name.toLowerCase() != q)
        .take(5)
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return Column(
      children: matches
          .map((k) => InkWell(
                onTap: () => setState(() {
                  _nameCtrl.text = k.name;
                  _nameCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: _nameCtrl.text.length));
                  if (AppCategories.all.contains(k.category)) {
                    _category = k.category;
                  }
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          size: 16, color: AppColors.textMut(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(k.name,
                            style:
                                TextStyle(color: AppColors.textPri(context))),
                      ),
                      Text(k.category,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMut(context))),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

'''

EDITS = {
  "lib/repo/services.dart": [
    ("import 'favorites_repo_firebase_impl.dart';\n",
     "import 'favorites_repo_firebase_impl.dart';\nimport 'known_items_repo.dart';\nimport 'known_items_repo_firebase_impl.dart';\n"),
    ("  static FavoritesRepoFirebaseImpl? _favorites;\n",
     "  static FavoritesRepoFirebaseImpl? _favorites;\n  static KnownItemsRepoFirebaseImpl? _knownItems;\n"),
    ("  static FavoritesRepo get favorites => _favorites!;\n",
     "  static FavoritesRepo get favorites => _favorites!;\n  static KnownItemsRepo get knownItems => _knownItems!;\n"),
    ("    await Future.wait([p.init(), s.init(), f.init()]);\n",
     "    final k = KnownItemsRepoFirebaseImpl();\n    await Future.wait([p.init(), s.init(), f.init(), k.init()]);\n"),
    ("    _favorites = f;\n\n    p.revisions",
     "    _favorites = f;\n    _knownItems = k;\n\n    p.revisions"),
    ("    _favorites?.dispose();\n",
     "    _favorites?.dispose();\n    _knownItems?.dispose();\n"),
    ("    _favorites = null;\n",
     "    _favorites = null;\n    _knownItems = null;\n"),
  ],
  "lib/viewmodel/pantry_vm.dart": [
    ("  Future<void> add(PantryItem item) async {\n    await Services.pantry.add(item);\n    notifyListeners();\n  }",
     "  Future<void> add(PantryItem item) async {\n    await Services.pantry.add(item);\n    await Services.knownItems.remember(item.name, item.category);\n    notifyListeners();\n  }"),
  ],
  "lib/view/screens/main/add_item_screen.dart": [
    ("import '../../../viewmodel/pantry_vm.dart';\n",
     "import '../../../viewmodel/pantry_vm.dart';\nimport '../../../repo/services.dart';\nimport '../../../repo/known_items_repo.dart';\n"),
    ("""          TextField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
          ),""",
     """          TextField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Fresh Chicken Breast'),
            onChanged: (_) => setState(() {}),
          ),
          _nameSuggestions(context),"""),
    ("            initialValue: _category,\n",
     "            key: ValueKey(_category),\n            initialValue: _category,\n"),
    ("  void _duplicateDialog(PantryItem newItem, PantryItem existing) {",
     SUGGEST + "  void _duplicateDialog(PantryItem newItem, PantryItem existing) {"),
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

info "Updating firestore.rules (adds shared known_items)..."
cat > firestore.rules <<'RULES'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Each user can read/write only their own subtree.
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Shared item catalogue for autocomplete: any signed-in user can read/add.
    match /known_items/{item} {
      allow read, write: if request.auth != null;
    }
  }
}
RULES
ok "firestore.rules updated."

flutter pub get
echo
err "RE-PUBLISH RULES: Firebase Console > Firestore > Rules -> paste firestore.rules -> Publish"
echo "   (or: firebase deploy --only firestore:rules). Without it, known_items is denied."
echo
ok "v5.1a-autocomplete complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Add an item (e.g. 'Milk', category Dairy). Add another later and start"
echo "      typing 'mi' -> 'Milk' suggestion appears; tap it -> name + category fill."
echo "   2. Firebase Console > Firestore: a top-level 'known_items' collection grows."
echo "   3. Type 'MILK' vs 'milk' -> same single suggestion (case-insensitive)."
echo
echo "  Then: git add -A && git commit -m 'v5.1a: known-items autocomplete' && git tag v5.1a"
echo "  Next: v5.1b (forgot password + profile doc + deletion cleanup)."
