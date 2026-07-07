#!/usr/bin/env bash
# =============================================================================
# ShelfLife v5.1c — OPTIONAL EXPIRY DATES
# =============================================================================
# Lets pantry items have no expiry date.
#   model/pantry_item.dart : expiryDate -> nullable; getters null-safe
#     (null = "No expiry": sorts last, status safe, label "No expiry")
#   add_item_screen.dart   : "No expiry" clear button + optional at save
#   pantry_item_sheet.dart : edit preserves/allows no-expiry
# The card, home counts, and sorting route through the model getters, so they
# need no changes.
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   cp ~/Downloads/v5_1c_optional_expiry.sh .
#   chmod +x v5_1c_optional_expiry.sh && ./v5_1c_optional_expiry.sh
# =============================================================================
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC}   $1"; }
err(){  echo -e "${RED}[ERR]${NC}  $1"; }

[ -f "pubspec.yaml" ] && [ -d "lib" ] || { err "Run from the shelflife/ project root."; exit 1; }
grep -q "imageUrl" lib/model/pantry_item.dart || { err "Run v5.1a-image first."; exit 1; }

info "Applying optional-expiry patches (all-or-nothing)..."
python3 - <<'PY'
import sys

EDITS = {
  "lib/model/pantry_item.dart": [
    ("  final DateTime expiryDate;\n", "  final DateTime? expiryDate;\n"),
    ("    required this.expiryDate,\n", "    this.expiryDate,\n"),
    ("""  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }""",
     """  int get daysUntilExpiry {
    final e = expiryDate;
    if (e == null) return 1000000;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(e.year, e.month, e.day);
    return exp.difference(today).inDays;
  }"""),
    ("""  String get expiryLabel {
    final d = daysUntilExpiry;
    final months = const [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final dateStr = '${months[expiryDate.month - 1]} ${expiryDate.day}';""",
     """  String get expiryLabel {
    final e = expiryDate;
    if (e == null) return 'No expiry';
    final d = daysUntilExpiry;
    final months = const [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final dateStr = '${months[e.month - 1]} ${e.day}';"""),
    ("""  double get progress {
    final total = expiryDate.difference(addedDate).inDays;""",
     """  double get progress {
    final e = expiryDate;
    if (e == null) return 0.0;
    final total = e.difference(addedDate).inDays;"""),
    ("        'expiry': expiryDate.toIso8601String(),\n",
     "        'expiry': expiryDate?.toIso8601String(),\n"),
    ("        expiryDate: DateTime.parse(m['expiry'] as String),\n",
     "        expiryDate: m['expiry'] != null\n            ? DateTime.parse(m['expiry'] as String)\n            : null,\n"),
  ],
  "lib/view/screens/main/add_item_screen.dart": [
    ("      expiryDate: _expiry ?? now.add(const Duration(days: 7)),\n",
     "      expiryDate: _expiry,\n"),
    ("""          InkWell(
            onTap: _pickExpiry,
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(_expiryText(),
                  style: TextStyle(
                    color: _expiry == null
                        ? AppColors.textMut(context)
                        : AppColors.textPri(context),
                  )),
            ),
          ),""",
     """          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickExpiry,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(_expiryText(),
                        style: TextStyle(
                          color: _expiry == null
                              ? AppColors.textMut(context)
                              : AppColors.textPri(context),
                        )),
                  ),
                ),
              ),
              if (_expiry != null)
                TextButton(
                  onPressed: () => setState(() => _expiry = null),
                  child: const Text('No expiry'),
                ),
            ],
          ),"""),
    ("      ? 'dd/mm/yyyy'\n", "      ? 'No expiry (optional)'\n"),
  ],
  "lib/view/screens/pantry_detail/pantry_item_sheet.dart": [
    ("  late DateTime _expiry;\n", "  DateTime? _expiry;\n"),
    ("    _expiry = e?.expiryDate ?? DateTime.now().add(const Duration(days: 7));\n",
     "    _expiry = e?.expiryDate;\n"),
    ("      initialDate: _expiry,\n",
     "      initialDate: _expiry ?? DateTime.now().add(const Duration(days: 7)),\n"),
    ("                  '${_expiry.year}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',\n",
     "                  _expiry == null\n                      ? 'No expiry'\n                      : '${_expiry!.year}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}',\n"),
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
ok "v5.1c complete."
echo -e "    ${BLUE}flutter analyze${NC}   (expect 0 errors)"
echo "  TEST:"
echo "   1. Add an item, DON'T pick an expiry -> saves; card shows 'No expiry';"
echo "      it sorts to the bottom of the pantry (never 'expiring soon')."
echo "   2. Add an item WITH an expiry -> behaves exactly as before."
echo "   3. Pick a date, then tap 'No expiry' -> clears it."
echo "   4. Edit an existing item -> its expiry (or lack of one) is preserved."
echo "   5. Firestore: a no-expiry item has no 'expiry' field (or null)."
echo
echo "  Then: git add -A && git commit -m 'v5.1c: optional expiry' && git tag v5.1c"
echo "  I'm sending v5.1b (profile doc) right after this."
