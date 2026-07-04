#!/usr/bin/env bash
# =============================================================================
# ShelfLife — Version 5.0 Update Script
# =============================================================================
# Firebase Auth + Firestore sync + autocomplete + v4 bug fixes.
# Run from the shelflife/ project root after v4 is in place.
#
#   cd /Users/anubhavsilwal/StudioProjects/shelflife
#   chmod +x v5_0.sh
#   ./v5_0.sh
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()     { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()    { echo -e "${RED}[ERR]${NC}  $1"; }

# =============================================================================
# 0. PRE-FLIGHT CHECKS
# =============================================================================
info "Pre-flight checks..."

if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then
  err "Run this from your project root (the shelflife/ folder)."
  exit 1
fi

if [ ! -f "lib/main.dart" ]; then
  err "lib/main.dart not found. Run v4 first."
  exit 1
fi

if [ ! -f "lib/firebase_options.dart" ]; then
  err "lib/firebase_options.dart missing. Run: flutterfire configure"
  exit 1
fi

if [ ! -f "android/app/google-services.json" ]; then
  err "android/app/google-services.json missing. Complete FlutterFire setup first."
  exit 1
fi

ok "All pre-flight checks passed."

# =============================================================================
# 1. UPDATE pubspec.yaml with Firebase deps
# =============================================================================
info "Updating pubspec.yaml..."

PROJECT_NAME=$(grep -E "^name:" pubspec.yaml | head -1 | awk '{print $2}')
PROJECT_NAME=${PROJECT_NAME:-shelflife}

cat > pubspec.yaml <<EOF
name: $PROJECT_NAME
description: "ShelfLife - Pantry management app."
publish_to: 'none'
version: 1.0.0+5

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  fl_chart: ^0.69.0
  intl: ^0.19.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.4
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/logo/
    - assets/items/
    - assets/recipes/
    - assets/onboarding/
    - assets/profile/
EOF
ok "pubspec.yaml updated with Firebase deps."

# =============================================================================
# 2. UPDATE android/app/build.gradle.kts for Firebase minSdk
# =============================================================================
info "Ensuring Android minSdk >= 23 for firebase_auth..."

BUILD_GRADLE="android/app/build.gradle.kts"
if [ -f "$BUILD_GRADLE" ]; then
  # firebase_auth requires minSdk 23+; bump if less
  if grep -q "minSdk = flutter.minSdkVersion" "$BUILD_GRADLE"; then
    sed -i.bak 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' "$BUILD_GRADLE"
    rm -f "${BUILD_GRADLE}.bak"
    ok "Android minSdk set to 23."
  elif grep -qE "minSdk = [0-9]+" "$BUILD_GRADLE"; then
    # Check current value; bump if too low
    CURRENT=$(grep -oE "minSdk = [0-9]+" "$BUILD_GRADLE" | head -1 | grep -oE "[0-9]+")
    if [ "$CURRENT" -lt 23 ]; then
      sed -i.bak "s/minSdk = ${CURRENT}/minSdk = 23/" "$BUILD_GRADLE"
      rm -f "${BUILD_GRADLE}.bak"
      ok "Android minSdk bumped from $CURRENT to 23."
    else
      ok "Android minSdk already >= 23."
    fi
  else
    warn "Could not auto-set minSdk in build.gradle.kts. Verify manually: minSdk >= 23."
  fi
fi

# =============================================================================
# 3. WIPE old v4 lib/ structure (keeping firebase_options.dart)
# =============================================================================
info "Preserving firebase_options.dart, wiping v4 lib/ structure..."

# Save firebase_options.dart temporarily
if [ -f "lib/firebase_options.dart" ]; then
  cp lib/firebase_options.dart /tmp/firebase_options.dart.bak
fi

rm -rf lib/constants lib/model lib/repo lib/viewmodel lib/view

# Restore firebase_options.dart
cp /tmp/firebase_options.dart.bak lib/firebase_options.dart
rm -f /tmp/firebase_options.dart.bak

ok "Old structure wiped, firebase_options.dart preserved."

# =============================================================================
# 4. CREATE MVVM FOLDER STRUCTURE
# =============================================================================
info "Creating MVVM folder structure..."

mkdir -p lib/constants
mkdir -p lib/model
mkdir -p lib/repo
mkdir -p lib/viewmodel
mkdir -p lib/view/theme
mkdir -p lib/view/widgets
mkdir -p lib/view/screens/auth
mkdir -p lib/view/screens/onboarding
mkdir -p lib/view/screens/main
mkdir -p lib/view/screens/pantry_detail
mkdir -p lib/view/screens/recipes
mkdir -p lib/view/screens/shopping
mkdir -p lib/view/screens/misc

ok "Folder structure created."

# =============================================================================
# 5. CONSTANTS
# =============================================================================
info "Writing constants..."

cat > lib/constants/app_colors.dart <<'DART'
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary       = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF2E7D32);
  static const Color primaryDeeper = Color(0xFF1B5E20);
  static const Color primaryLight  = Color(0xFFE8F5E9);

  // Light
  static const Color lightBackground    = Color(0xFFF5F6FA);
  static const Color lightCard          = Colors.white;
  static const Color lightDivider       = Color(0xFFE5E7EB);
  static const Color lightTextPrimary   = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted     = Color(0xFF9CA3AF);
  static const Color lightChipBg        = Color(0xFFF3F4F6);
  static const Color lightChipUnselected= Color(0xFFE3F2FD);
  static const Color lightInputFill     = Colors.white;
  static const Color lightInfoBg        = Color(0xFFEFF6FF);

  // Dark
  static const Color darkBackground     = Color(0xFF121417);
  static const Color darkCard           = Color(0xFF1E2126);
  static const Color darkDivider        = Color(0xFF2D3138);
  static const Color darkTextPrimary    = Color(0xFFF3F4F6);
  static const Color darkTextSecondary  = Color(0xFFB0B4BA);
  static const Color darkTextMuted      = Color(0xFF6B7280);
  static const Color darkChipBg         = Color(0xFF262A30);
  static const Color darkChipUnselected = Color(0xFF1F2429);
  static const Color darkInputFill      = Color(0xFF1E2126);
  static const Color darkInfoBg         = Color(0xFF18242E);

  // Status
  static const Color warning      = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color danger       = Color(0xFFF44336);
  static const Color dangerLight  = Color(0xFFFFEBEE);
  static const Color safe         = Color(0xFF16A34A);
  static const Color safeLight    = Color(0xFFE8F5E9);
  static const Color neutral      = Color(0xFF9CA3AF);

  // Social
  static const Color facebookBlue = Color(0xFF1877F2);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c)        => _isDark(c) ? darkBackground   : lightBackground;
  static Color card(BuildContext c)      => _isDark(c) ? darkCard         : lightCard;
  static Color divider(BuildContext c)   => _isDark(c) ? darkDivider      : lightDivider;
  static Color textPri(BuildContext c)   => _isDark(c) ? darkTextPrimary  : lightTextPrimary;
  static Color textSec(BuildContext c)   => _isDark(c) ? darkTextSecondary: lightTextSecondary;
  static Color textMut(BuildContext c)   => _isDark(c) ? darkTextMuted    : lightTextMuted;
  static Color chipBg(BuildContext c)    => _isDark(c) ? darkChipBg       : lightChipBg;
  static Color infoBg(BuildContext c)    => _isDark(c) ? darkInfoBg       : lightInfoBg;
  static Color chipUnsel(BuildContext c) => _isDark(c) ? darkChipUnselected : lightChipUnselected;
}
DART

cat > lib/constants/app_sizes.dart <<'DART'
class AppSizes {
  AppSizes._();
  static const double pageHPad      = 20;
  static const double cardRadius    = 14;
  static const double inputRadius   = 12;
  static const double pillRadius    = 28;
  static const double appBarHeight  = 64;
  static const double itemImage     = 60;
  static const double narrowScreen  = 340;
  static const Duration anim        = Duration(milliseconds: 150);
}
DART

cat > lib/constants/app_strings.dart <<'DART'
class AppStrings {
  AppStrings._();
  static const appName     = 'ShelfLife';
  static const tagline     = 'Freshness at your fingertips';
  static const defaultName = 'ShelfLife User';
  static const cancel      = 'Cancel';
  static const save        = 'Save';
  static const delete      = 'Delete';
  static const add         = 'Add';
  static const undo        = 'UNDO';
  // Firestore
  static const usersCol         = 'users';
  static const pantryCol        = 'pantry';
  static const shoppingCol      = 'shopping';
  static const favoritesCol     = 'favorites';
  static const profileDoc       = 'profile';
  static const meta             = 'meta';
  static const preferencesDoc   = 'preferences';
}
DART

cat > lib/constants/app_categories.dart <<'DART'
class AppCategories {
  AppCategories._();
  static const List<String> all = [
    'Dairy',
    'Produce',
    'Meat',
    'Grains',
    'Beverages',
    'Snacks',
    'Other',
  ];
  static const List<String> filterChips = [
    'All',
    'Favorites',
    'Dairy',
    'Produce',
    'Meat',
    'Grains',
    'Finished',
  ];
  static const List<String> commonAllergens = [
    'Peanuts', 'Dairy', 'Soy', 'Shellfish',
    'Gluten', 'Tree Nuts', 'Eggs', 'Fish',
  ];
  static const List<String> dietaryPrefs = [
    'Vegan', 'Keto', 'Vegetarian', 'Paleo',
    'Gluten-free', 'Dairy-free', 'Pescatarian', 'Low Carb',
  ];
}
DART

cat > lib/constants/app_units.dart <<'DART'
enum UnitGroup { mass, volume, count }

class AppUnit {
  final String code;
  final String label;
  final UnitGroup group;
  final double toBase;
  const AppUnit(this.code, this.label, this.group, this.toBase);
}

class AppUnits {
  AppUnits._();
  static const g  = AppUnit('g',  'g',  UnitGroup.mass, 1.0);
  static const kg = AppUnit('kg', 'kg', UnitGroup.mass, 1000.0);
  static const oz = AppUnit('oz', 'oz', UnitGroup.mass, 28.3495);
  static const lb = AppUnit('lb', 'lb', UnitGroup.mass, 453.592);
  static const ml    = AppUnit('ml',   'ml',  UnitGroup.volume, 1.0);
  static const l     = AppUnit('l',    'L',   UnitGroup.volume, 1000.0);
  static const tsp   = AppUnit('tsp',  'tsp', UnitGroup.volume, 4.92892);
  static const tbsp  = AppUnit('tbsp', 'tbsp',UnitGroup.volume, 14.7868);
  static const cup   = AppUnit('cup',  'cup', UnitGroup.volume, 236.588);
  static const flOz  = AppUnit('fl_oz','fl oz',UnitGroup.volume,29.5735);
  static const unit  = AppUnit('unit',  'unit',  UnitGroup.count, 1.0);
  static const piece = AppUnit('piece', 'piece', UnitGroup.count, 1.0);
  static const pack  = AppUnit('pack',  'pack',  UnitGroup.count, 1.0);
  static const bag   = AppUnit('bag',   'bag',   UnitGroup.count, 1.0);

  static const all = <AppUnit>[
    unit, piece, pack, bag,
    g, kg, oz, lb,
    ml, l, tsp, tbsp, cup, flOz,
  ];

  static AppUnit byCode(String code) {
    for (final u in all) {
      if (u.code == code) return u;
    }
    return unit;
  }

  static String? secondaryDisplay(double qty, AppUnit unit) {
    if (qty <= 0) return null;
    switch (unit.group) {
      case UnitGroup.mass:
        final inGrams = qty * unit.toBase;
        if (unit.code == 'g' || unit.code == 'kg') {
          return '≈ ${_fmt(inGrams / AppUnits.lb.toBase)} lb';
        } else {
          if (inGrams >= 1000) return '≈ ${_fmt(inGrams / 1000)} kg';
          return '≈ ${_fmt(inGrams)} g';
        }
      case UnitGroup.volume:
        final inMl = qty * unit.toBase;
        if (unit.code == 'ml' || unit.code == 'l') {
          return '≈ ${_fmt(inMl / AppUnits.flOz.toBase)} fl oz';
        } else {
          if (inMl >= 1000) return '≈ ${_fmt(inMl / 1000)} L';
          return '≈ ${_fmt(inMl)} ml';
        }
      case UnitGroup.count:
        return null;
    }
  }

  static String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
DART

ok "Constants written."

# =============================================================================
# 6. MODELS — with nullable expiry, KnownItem for autocomplete, UserProfile
# =============================================================================
info "Writing models..."

cat > lib/model/enums.dart <<'DART'
enum ExpiryStatus { safe, soon, expired, noExpiry }

enum ItemStatus { active, finished }

extension ItemStatusX on ItemStatus {
  String get serialized => name;
  static ItemStatus parse(String? s) =>
      s == 'finished' ? ItemStatus.finished : ItemStatus.active;
}

enum StorageLocation { fridge, freezer, pantry }

extension StorageLocationX on StorageLocation {
  String get label {
    switch (this) {
      case StorageLocation.fridge:  return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.pantry:  return 'Pantry';
    }
  }
  static StorageLocation parse(String? s) {
    switch (s) {
      case 'freezer': return StorageLocation.freezer;
      case 'pantry':  return StorageLocation.pantry;
      default:        return StorageLocation.fridge;
    }
  }
  String get serialized => name;
}
DART

# ---- PantryItem (expiryDate now nullable) ---------------------------------
cat > lib/model/pantry_item.dart <<'DART'
import 'enums.dart';

class PantryItem {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unitCode;
  final DateTime? expiryDate;   // NULLABLE — v5.0 bug fix #8
  final DateTime addedDate;
  final DateTime? purchaseDate;
  final String? imageAsset;
  final String? imageUrl;       // NEW: for future Cloudinary URLs / user uploads
  final String? imagePath;
  final String? notes;
  final StorageLocation storage;
  final bool favorite;
  final ItemStatus status;

  const PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitCode,
    this.expiryDate,
    required this.addedDate,
    this.purchaseDate,
    this.imageAsset,
    this.imageUrl,
    this.imagePath,
    this.notes,
    this.storage = StorageLocation.fridge,
    this.favorite = false,
    this.status = ItemStatus.active,
  });

  bool get hasExpiry => expiryDate != null;

  int get daysUntilExpiry {
    if (expiryDate == null) return 9999; // sentinel — treated as "far future"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(
        expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return exp.difference(today).inDays;
  }

  ExpiryStatus get expiryStatus {
    if (expiryDate == null) return ExpiryStatus.noExpiry;
    final d = daysUntilExpiry;
    if (d <= 1) return ExpiryStatus.expired;
    if (d <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.safe;
  }

  String get expiryLabel {
    if (expiryDate == null) return 'Expiry not set';
    final d = daysUntilExpiry;
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final dateStr = '${months[expiryDate!.month - 1]} ${expiryDate!.day}';
    if (d < 0)  return 'Expired ($dateStr)';
    if (d == 0) return 'Expires Today';
    if (d == 1) return 'Expires tomorrow';
    if (d <= 7) return 'Expires in $d days ($dateStr)';
    return 'Exp: $dateStr';
  }

  String get quantityLabel {
    if (quantity == quantity.truncate()) {
      return '${quantity.toInt()} $unitCode';
    }
    return '${quantity.toStringAsFixed(1)} $unitCode';
  }

  double get progress {
    if (expiryDate == null) return 0.0;
    final total = expiryDate!.difference(addedDate).inDays;
    if (total <= 0) return 1.0;
    final used = DateTime.now().difference(addedDate).inDays;
    return (used / total).clamp(0.0, 1.0);
  }

  bool get isFinished => status == ItemStatus.finished;
  bool get isActive => status == ItemStatus.active;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unitCode': unitCode,
        'expiry': expiryDate?.toIso8601String(),
        'added': addedDate.toIso8601String(),
        'purchaseDate': purchaseDate?.toIso8601String(),
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'notes': notes,
        'storage': storage.serialized,
        'favorite': favorite,
        'status': status.serialized,
      };

  factory PantryItem.fromMap(Map m) => PantryItem(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        quantity: _toDouble(m['quantity']),
        unitCode: (m['unitCode'] as String?) ?? 'unit',
        expiryDate: m['expiry'] != null
            ? DateTime.parse(m['expiry'] as String)
            : null,
        addedDate: DateTime.parse(m['added'] as String),
        purchaseDate: m['purchaseDate'] != null
            ? DateTime.parse(m['purchaseDate'] as String)
            : null,
        imageAsset: m['imageAsset'] as String?,
        imageUrl: m['imageUrl'] as String?,
        imagePath: m['imagePath'] as String?,
        notes: m['notes'] as String?,
        storage: StorageLocationX.parse(m['storage'] as String?),
        favorite: (m['favorite'] as bool?) ?? false,
        status: ItemStatusX.parse(m['status'] as String?),
      );

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
    }
    return 1.0;
  }

  PantryItem copyWith({
    String? name,
    String? category,
    double? quantity,
    String? unitCode,
    DateTime? expiryDate,
    bool clearExpiry = false,
    DateTime? addedDate,
    DateTime? purchaseDate,
    bool clearPurchase = false,
    String? imageAsset,
    String? imageUrl,
    String? imagePath,
    String? notes,
    StorageLocation? storage,
    bool? favorite,
    ItemStatus? status,
  }) =>
      PantryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        unitCode: unitCode ?? this.unitCode,
        expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
        addedDate: addedDate ?? this.addedDate,
        purchaseDate:
            clearPurchase ? null : (purchaseDate ?? this.purchaseDate),
        imageAsset: imageAsset ?? this.imageAsset,
        imageUrl: imageUrl ?? this.imageUrl,
        imagePath: imagePath ?? this.imagePath,
        notes: notes ?? this.notes,
        storage: storage ?? this.storage,
        favorite: favorite ?? this.favorite,
        status: status ?? this.status,
      );
}
DART

# ---- Recipe (unchanged from v4) -------------------------------------------
cat > lib/model/recipe.dart <<'DART'
class Recipe {
  final String id;
  final String title;
  final String time;
  final int timeMinutes;
  final String difficulty;
  final String? imageAsset;
  final bool allFound;
  final String? missingNote;
  final List<String> missingIngredients;
  final bool urgent;
  final String description;
  final List<String> ingredients;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.timeMinutes,
    required this.difficulty,
    this.imageAsset,
    this.allFound = true,
    this.missingNote,
    this.missingIngredients = const [],
    this.urgent = false,
    this.description = '',
    this.ingredients = const [],
    this.tags = const [],
  });
}
DART

# ---- ShoppingItem ---------------------------------------------------------
cat > lib/model/shopping_item.dart <<'DART'
class ShoppingItem {
  final String id;
  String name;
  String? note;
  bool checked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.note,
    this.checked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'checked': checked,
      };

  factory ShoppingItem.fromMap(Map m) => ShoppingItem(
        id: m['id'] as String,
        name: m['name'] as String,
        note: m['note'] as String?,
        checked: (m['checked'] as bool?) ?? false,
      );
}
DART

# ---- KnownItem (autocomplete catalog) -------------------------------------
cat > lib/model/known_item.dart <<'DART'
/// Persistent catalog entry — used by autocomplete when typing item name.
/// Populated from seed data on first launch, then every add/edit.
class KnownItem {
  final String nameLower;    // key (lowercased)
  final String name;
  final String category;
  final String? imageAsset;
  final String? imageUrl;
  final String defaultUnit;
  final DateTime lastSeen;

  const KnownItem({
    required this.nameLower,
    required this.name,
    required this.category,
    this.imageAsset,
    this.imageUrl,
    this.defaultUnit = 'unit',
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
        'nameLower': nameLower,
        'name': name,
        'category': category,
        'imageAsset': imageAsset,
        'imageUrl': imageUrl,
        'defaultUnit': defaultUnit,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory KnownItem.fromMap(Map m) => KnownItem(
        nameLower: m['nameLower'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        imageAsset: m['imageAsset'] as String?,
        imageUrl: m['imageUrl'] as String?,
        defaultUnit: (m['defaultUnit'] as String?) ?? 'unit',
        lastSeen: DateTime.parse(m['lastSeen'] as String),
      );
}
DART

# ---- UserProfile (dietary prefs + allergies — bug fix #6) -----------------
cat > lib/model/user_profile.dart <<'DART'
class UserProfile {
  final String? displayName;
  final String? email;
  final DateTime? birthdate;
  final String? gender;
  final List<String> dietaryPrefs;
  final List<String> allergies;
  final bool darkMode;

  const UserProfile({
    this.displayName,
    this.email,
    this.birthdate,
    this.gender,
    this.dietaryPrefs = const [],
    this.allergies = const [],
    this.darkMode = false,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'birthdate': birthdate?.toIso8601String(),
        'gender': gender,
        'dietaryPrefs': dietaryPrefs,
        'allergies': allergies,
        'darkMode': darkMode,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        displayName: m['displayName'] as String?,
        email: m['email'] as String?,
        birthdate: m['birthdate'] != null
            ? DateTime.parse(m['birthdate'] as String)
            : null,
        gender: m['gender'] as String?,
        dietaryPrefs:
            List<String>.from((m['dietaryPrefs'] as List?) ?? const []),
        allergies: List<String>.from((m['allergies'] as List?) ?? const []),
        darkMode: (m['darkMode'] as bool?) ?? false,
      );

  UserProfile copyWith({
    String? displayName,
    String? email,
    DateTime? birthdate,
    String? gender,
    List<String>? dietaryPrefs,
    List<String>? allergies,
    bool? darkMode,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        birthdate: birthdate ?? this.birthdate,
        gender: gender ?? this.gender,
        dietaryPrefs: dietaryPrefs ?? this.dietaryPrefs,
        allergies: allergies ?? this.allergies,
        darkMode: darkMode ?? this.darkMode,
      );
}
DART

ok "Models written."

# =============================================================================
# 7. SEED + RECIPE DATA (with fixed reference dates — bug fix #1)
# =============================================================================
info "Writing seed + recipe data..."

cat > lib/repo/seed_data.dart <<'DART'
/// First-launch seed data. Uses relative day offsets from seedReferenceDate
/// (bug fix #1: reseeded items no longer always expire "today").
class SeedData {
  /// Days-from-now offset — resolved to real DateTime at seed time.
  static Map<String, dynamic> _entry(
    int n,
    String name,
    String category,
    double quantity,
    String unitCode,
    int expInDays,
    int addedAgo, {
    String? assetName,
    String storage = 'fridge',
    String? notes,
    bool favorite = false,
    bool hasExpiry = true,
  }) {
    final now = DateTime.now();
    return {
      'id': 'p_$n',
      'name': name,
      'category': category,
      'quantity': quantity,
      'unitCode': unitCode,
      'expiry': hasExpiry
          ? now.add(Duration(days: expInDays)).toIso8601String()
          : null,
      'added': now.subtract(Duration(days: addedAgo)).toIso8601String(),
      'purchaseDate':
          now.subtract(Duration(days: addedAgo)).toIso8601String(),
      'imageAsset': assetName != null ? 'assets/items/$assetName.png' : null,
      'imageUrl': null,
      'imagePath': null,
      'notes': notes,
      'storage': storage,
      'favorite': favorite,
      'status': 'active',
    };
  }

  static List<Map<String, dynamic>> get pantry => [
        _entry(1, 'Whole Milk', 'Dairy', 1, 'unit', 0, 6,
            assetName: 'whole_milk', storage: 'fridge', notes: 'Top shelf'),
        _entry(2, 'Baby Spinach', 'Produce', 1, 'bag', 2, 3,
            assetName: 'baby_spinach', favorite: true),
        _entry(3, 'Greek Yogurt', 'Dairy', 500, 'g', 3, 4,
            assetName: 'greek_yogurt'),
        _entry(4, 'Avocados', 'Produce', 2, 'piece', 5, 2,
            assetName: 'avocados', storage: 'pantry'),
        _entry(5, 'Strawberries', 'Produce', 1, 'pack', 6, 2,
            assetName: 'strawberries', favorite: true),
        _entry(6, 'Baby Carrots', 'Produce', 2, 'bag', 3, 4,
            assetName: 'baby_carrots'),
        _entry(7, 'Chicken Breast', 'Meat', 1.5, 'lb', 12, 1,
            assetName: 'chicken_breast',
            storage: 'freezer',
            notes: 'Vacuum sealed'),
        _entry(8, 'Chicken Breast', 'Meat', 1, 'lb', 4, 1,
            assetName: 'chicken_breast_2'),
        _entry(9, 'Large Eggs (12pk)', 'Dairy', 1, 'pack', 8, 1,
            assetName: 'large_eggs'),
        _entry(10, 'Salted Butter', 'Dairy', 4, 'piece', 12, 2,
            assetName: 'salted_butter'),
        _entry(11, 'Red Bell Peppers', 'Produce', 2, 'piece', 3, 2,
            assetName: 'red_bell_peppers'),
        _entry(12, 'Organic Kale', 'Produce', 1, 'bag', 4, 1,
            assetName: 'organic_kale'),
        _entry(13, 'Whole-Wheat Bread', 'Grains', 1, 'piece', 5, 2,
            storage: 'pantry', notes: 'Bread bin on counter'),
        _entry(14, 'Cheddar Cheese', 'Dairy', 250, 'g', 20, 3),
        _entry(15, 'Tomatoes', 'Produce', 6, 'piece', 7, 1,
            storage: 'pantry'),
        _entry(16, 'Salmon Fillet', 'Meat', 2, 'piece', 2, 0,
            notes: 'Wild caught'),
        _entry(17, 'Olive Oil', 'Other', 500, 'ml', 0, 30,
            storage: 'pantry',
            notes: 'Extra virgin',
            hasExpiry: false),
        _entry(18, 'Brown Rice', 'Grains', 2, 'kg', 0, 15,
            storage: 'pantry',
            hasExpiry: false),
        _entry(19, 'Blueberries', 'Produce', 1, 'pack', 4, 1),
        _entry(20, 'Ground Beef', 'Meat', 500, 'g', 1, 2,
            notes: 'Use today or freeze'),
      ];

  static List<Map<String, dynamic>> get shopping => [
        {'id': 's_1', 'name': 'Pancetta', 'note': 'Expired item', 'checked': false},
        {'id': 's_2', 'name': 'Parmesan', 'note': 'From recipe: Spaghetti Carbonara', 'checked': false},
        {'id': 's_3', 'name': 'Milk', 'note': 'Low stock', 'checked': false},
        {'id': 's_4', 'name': 'Whole-Wheat Bread', 'note': null, 'checked': false},
        {'id': 's_5', 'name': 'Honey', 'note': 'For Honey Glazed Chicken', 'checked': false},
        {'id': 's_6', 'name': 'Fresh Basil', 'note': null, 'checked': false},
        {'id': 's_7', 'name': 'Garlic (1 bulb)', 'note': null, 'checked': false},
        {'id': 's_8', 'name': 'Lemons (4)', 'note': null, 'checked': false},
        {'id': 's_9', 'name': 'Pasta', 'note': null, 'checked': false},
        {'id': 's_10', 'name': 'Coffee Beans', 'note': '250g, medium roast', 'checked': false},
        {'id': 's_11', 'name': 'Almond Milk', 'note': 'Unsweetened', 'checked': false},
        {'id': 's_12', 'name': 'Bananas', 'note': null, 'checked': false},
      ];

  static List<String> get favoriteRecipeIds => ['r_2', 'r_4', 'r_7'];

  /// KnownItems for autocomplete — populated on first launch.
  /// Keeps names/images/categories available even after user deletes from pantry.
  static List<Map<String, dynamic>> get knownItems => pantry.map((p) {
        final n = (p['name'] as String).toLowerCase();
        return {
          'nameLower': n,
          'name': p['name'],
          'category': p['category'],
          'imageAsset': p['imageAsset'],
          'imageUrl': null,
          'defaultUnit': p['unitCode'],
          'lastSeen': DateTime.now().toIso8601String(),
        };
      }).toList();
}
DART

cat > lib/repo/recipe_data.dart <<'DART'
import '../model/recipe.dart';

class RecipeData {
  static const List<Recipe> all = [
    Recipe(
      id: 'r_1',
      title: 'Spinach & Berry Summer Salad',
      time: '15 mins', timeMinutes: 15,
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/spinach_berry_salad.png',
      urgent: true,
      description: 'A refreshing salad using your expiring spinach and strawberries.',
      ingredients: ['Baby Spinach', 'Strawberries', 'Feta Cheese', 'Walnuts', 'Balsamic Glaze'],
      tags: ['Use First', 'Vegetarian', 'Quick'],
    ),
    Recipe(
      id: 'r_2',
      title: 'Zucchini & Leek Cream Soup',
      time: '30 mins', timeMinutes: 30,
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/zucchini_leek_soup.png',
      description: 'Velvety soup perfect for cool evenings.',
      ingredients: ['Zucchini', 'Leeks', 'Cream', 'Garlic', 'Vegetable Stock'],
      tags: ['Vegetarian', 'Comfort Food'],
    ),
    Recipe(
      id: 'r_3',
      title: 'Berry Compote Parfait',
      time: '10 mins', timeMinutes: 10,
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/berry_compote_parfait.png',
      description: 'Layered yogurt parfait with warm berry compote and granola.',
      ingredients: ['Greek Yogurt', 'Strawberries', 'Blueberries', 'Granola', 'Honey'],
      tags: ['Breakfast', 'Quick'],
    ),
    Recipe(
      id: 'r_4',
      title: 'Lemon Garlic Stir-Fry',
      time: '20 mins', timeMinutes: 20,
      difficulty: 'Easy',
      imageAsset: 'assets/recipes/lemon_garlic_stirfry.png',
      description: 'Quick stir-fry with bright lemon and aromatic garlic.',
      ingredients: ['Chicken Breast', 'Bell Peppers', 'Garlic', 'Lemons', 'Soy Sauce'],
      tags: ['Quick', 'High Protein'],
    ),
    Recipe(
      id: 'r_5',
      title: 'Honey Glazed Chicken',
      time: '35 mins', timeMinutes: 35,
      difficulty: 'Medium',
      imageAsset: 'assets/recipes/honey_glazed_chicken.png',
      allFound: false,
      missingNote: 'Need: Honey',
      missingIngredients: ['Honey'],
      description: 'Sticky-sweet glaze on tender chicken with asparagus.',
      ingredients: ['Chicken Breast', 'Honey', 'Soy Sauce', 'Garlic', 'Asparagus'],
      tags: ['Dinner'],
    ),
    Recipe(
      id: 'r_6',
      title: 'Rainbow Veggie Wrap',
      time: '10 mins', timeMinutes: 10,
      difficulty: 'Very Easy',
      imageAsset: 'assets/recipes/rainbow_veggie_wrap.png',
      description: 'Colorful, crunchy wrap with hummus and fresh vegetables.',
      ingredients: ['Tortilla', 'Hummus', 'Bell Peppers', 'Carrots', 'Spinach', 'Cucumber'],
      tags: ['Vegetarian', 'Lunch', 'Quick'],
    ),
    Recipe(
      id: 'r_7',
      title: 'Avocado Egg Toast',
      time: '10 mins', timeMinutes: 10,
      difficulty: 'Very Easy',
      description: 'Creamy avocado and runny egg on toasted bread.',
      ingredients: ['Whole-Wheat Bread', 'Avocados', 'Large Eggs', 'Chili Flakes', 'Lemon'],
      tags: ['Breakfast', 'Quick'],
    ),
    Recipe(
      id: 'r_8',
      title: 'Salmon Teriyaki Bowl',
      time: '25 mins', timeMinutes: 25,
      difficulty: 'Medium',
      description: 'Glazed salmon over brown rice with steamed veggies.',
      ingredients: ['Salmon Fillet', 'Brown Rice', 'Soy Sauce', 'Honey', 'Broccoli'],
      tags: ['High Protein', 'Dinner'],
    ),
    Recipe(
      id: 'r_9',
      title: 'Classic Spaghetti Carbonara',
      time: '20 mins', timeMinutes: 20,
      difficulty: 'Medium',
      allFound: false,
      missingNote: 'Need: Pancetta, Parmesan',
      missingIngredients: ['Pancetta', 'Parmesan'],
      description: 'Authentic Roman pasta with eggs, cheese, and pepper.',
      ingredients: ['Pasta', 'Large Eggs', 'Parmesan', 'Pancetta', 'Black Pepper'],
      tags: ['Italian', 'Dinner'],
    ),
    Recipe(
      id: 'r_10',
      title: 'Roasted Veggie Tray Bake',
      time: '40 mins', timeMinutes: 40,
      difficulty: 'Easy',
      description: 'One-pan roasted vegetables with olive oil and herbs.',
      ingredients: ['Bell Peppers', 'Tomatoes', 'Olive Oil', 'Carrots', 'Garlic'],
      tags: ['Vegetarian', 'Meal Prep'],
    ),
    Recipe(
      id: 'r_11',
      title: 'Yogurt Berry Smoothie',
      time: '5 mins', timeMinutes: 5,
      difficulty: 'Very Easy',
      description: 'Quick energizing smoothie packed with antioxidants.',
      ingredients: ['Greek Yogurt', 'Blueberries', 'Strawberries', 'Honey', 'Almond Milk'],
      tags: ['Breakfast', 'Smoothie', 'Quick'],
    ),
    Recipe(
      id: 'r_12',
      title: 'Cheesy Beef Tacos',
      time: '25 mins', timeMinutes: 25,
      difficulty: 'Easy',
      description: 'Quick weeknight tacos with seasoned ground beef and cheese.',
      ingredients: ['Ground Beef', 'Cheddar Cheese', 'Tortilla', 'Tomatoes', 'Lemons'],
      tags: ['Dinner', 'Family Friendly'],
    ),
    Recipe(
      id: 'r_13',
      title: 'Kale & Quinoa Power Bowl',
      time: '20 mins', timeMinutes: 20,
      difficulty: 'Easy',
      description: 'Nutrient-packed bowl with lemon-tahini dressing.',
      ingredients: ['Organic Kale', 'Brown Rice', 'Avocados', 'Lemons', 'Olive Oil'],
      tags: ['Vegetarian', 'Healthy', 'Meal Prep'],
    ),
    Recipe(
      id: 'r_14',
      title: 'Garlic Butter Shrimp',
      time: '15 mins', timeMinutes: 15,
      difficulty: 'Easy',
      description: 'Quick shrimp sautéed in garlic butter with lemon.',
      ingredients: ['Salted Butter', 'Garlic', 'Lemons', 'Fresh Basil'],
      tags: ['Quick', 'Seafood'],
    ),
    Recipe(
      id: 'r_15',
      title: 'Eggs Benedict',
      time: '25 mins', timeMinutes: 25,
      difficulty: 'Medium',
      description: 'Brunch classic with poached eggs and hollandaise sauce.',
      ingredients: ['Large Eggs', 'Whole-Wheat Bread', 'Salted Butter', 'Lemons'],
      tags: ['Brunch'],
    ),
  ];

  static Recipe? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<Recipe> get useFirst => all.where((r) => r.urgent).toList();
  static List<Recipe> get matches =>
      all.where((r) => !r.urgent).take(4).toList();
}
DART

ok "Seed + recipe data written."

# =============================================================================
# 8. REPO INTERFACES + HIVE IMPLEMENTATIONS (with per-user namespacing)
# =============================================================================
info "Writing repo interfaces + Hive implementations..."

# ---- pantry_repo interface -------------------------------------------------
cat > lib/repo/pantry_repo.dart <<'DART'
import '../model/pantry_item.dart';

abstract class PantryRepo {
  Future<void> init();

  List<PantryItem> getAll();
  PantryItem? getById(String id);

  Future<void> add(PantryItem item);
  Future<void> update(PantryItem item);
  Future<void> delete(String id);
  Future<void> clear();

  /// Called by SyncService — accepts a raw map (already Firestore-shaped).
  Future<void> addRaw(Map<String, dynamic> map);
}
DART

# ---- pantry_repo_impl (Hive) — accepts user id for namespacing ------------
cat > lib/repo/pantry_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';
import 'seed_data.dart';

class PantryRepoImpl implements PantryRepo {
  final String? uid;
  PantryRepoImpl({this.uid});
  String get _boxName => uid == null ? 'pantry_guest' : 'pantry_$uid';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<PantryItem> getAll() {
    return _box.values
        .map((v) => PantryItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  @override
  PantryItem? getById(String id) {
    final v = _box.get(id);
    if (v == null) return null;
    return PantryItem.fromMap(Map<String, dynamic>.from(v as Map));
  }

  @override
  Future<void> add(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    final id = map['id'] as String;
    await _box.put(id, map);
  }

  @override
  Future<void> update(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final m in SeedData.pantry) {
      await _box.put(m['id'], m);
    }
  }
}
DART

# ---- shopping_repo + impl --------------------------------------------------
cat > lib/repo/shopping_repo.dart <<'DART'
import '../model/shopping_item.dart';

abstract class ShoppingRepo {
  Future<void> init();
  List<ShoppingItem> getAll();
  Future<void> add(ShoppingItem item);
  Future<void> update(ShoppingItem item);
  Future<void> delete(String id);
  Future<void> clear();
  Future<void> addRaw(Map<String, dynamic> map);
}
DART

cat > lib/repo/shopping_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';
import 'seed_data.dart';

class ShoppingRepoImpl implements ShoppingRepo {
  final String? uid;
  ShoppingRepoImpl({this.uid});
  String get _boxName => uid == null ? 'shopping_guest' : 'shopping_$uid';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<ShoppingItem> getAll() {
    return _box.values
        .map((v) => ShoppingItem.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  @override
  Future<void> add(ShoppingItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    await _box.put(map['id'] as String, map);
  }

  @override
  Future<void> update(ShoppingItem item) async {
    await _box.put(item.id, item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final m in SeedData.shopping) {
      await _box.put(m['id'], m);
    }
  }
}
DART

# ---- favorites_repo + impl -------------------------------------------------
cat > lib/repo/favorites_repo.dart <<'DART'
abstract class FavoritesRepo {
  Future<void> init();
  Set<String> getAll();
  bool isFavorite(String recipeId);
  Future<void> toggle(String recipeId);
  Future<void> setAll(Set<String> ids);
  Future<void> clear();
}
DART

cat > lib/repo/favorites_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import 'favorites_repo.dart';
import 'seed_data.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  final String? uid;
  FavoritesRepoImpl({this.uid});
  String get _boxName => uid == null ? 'favorites_guest' : 'favorites_$uid';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  Set<String> getAll() => _box.keys.map((k) => k.toString()).toSet();

  @override
  bool isFavorite(String recipeId) => _box.get(recipeId) == true;

  @override
  Future<void> toggle(String recipeId) async {
    if (isFavorite(recipeId)) {
      await _box.delete(recipeId);
    } else {
      await _box.put(recipeId, true);
    }
  }

  @override
  Future<void> setAll(Set<String> ids) async {
    await _box.clear();
    for (final id in ids) {
      await _box.put(id, true);
    }
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final id in SeedData.favoriteRecipeIds) {
      await _box.put(id, true);
    }
  }
}
DART

# ---- settings_repo + impl (device-local: dark mode + first-launch flag) ---
cat > lib/repo/settings_repo.dart <<'DART'
abstract class SettingsRepo {
  Future<void> init();
  bool get darkMode;
  Future<void> setDarkMode(bool v);
  bool get seeded;
  Future<void> markSeeded();
  Future<void> clearSeeded();
  bool get knownItemsSeeded;
  Future<void> markKnownItemsSeeded();
}
DART

cat > lib/repo/settings_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_repo.dart';

class SettingsRepoImpl implements SettingsRepo {
  // Settings are device-local, not per-user. Dark mode preference etc.
  static const _boxName = 'settings';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  bool get darkMode => _box.get('darkMode', defaultValue: false) as bool;

  @override
  Future<void> setDarkMode(bool v) async => _box.put('darkMode', v);

  @override
  bool get seeded => _box.get('seeded', defaultValue: false) as bool;

  @override
  Future<void> markSeeded() async => _box.put('seeded', true);

  @override
  Future<void> clearSeeded() async => _box.delete('seeded');

  @override
  bool get knownItemsSeeded =>
      _box.get('knownItemsSeeded', defaultValue: false) as bool;

  @override
  Future<void> markKnownItemsSeeded() async =>
      _box.put('knownItemsSeeded', true);
}
DART

# ---- recipe_repo + impl (static, unchanged) -------------------------------
cat > lib/repo/recipe_repo.dart <<'DART'
import '../model/recipe.dart';

abstract class RecipeRepo {
  List<Recipe> getAll();
  Recipe? getById(String id);
  List<Recipe> getUseFirst();
  List<Recipe> getMatches();
}
DART

cat > lib/repo/recipe_repo_impl.dart <<'DART'
import '../model/recipe.dart';
import 'recipe_repo.dart';
import 'recipe_data.dart';

class RecipeRepoImpl implements RecipeRepo {
  @override
  List<Recipe> getAll() => RecipeData.all;
  @override
  Recipe? getById(String id) => RecipeData.byId(id);
  @override
  List<Recipe> getUseFirst() => RecipeData.useFirst;
  @override
  List<Recipe> getMatches() => RecipeData.matches;
}
DART

ok "Hive repo interfaces + implementations written."

# =============================================================================
# 9. KNOWN_ITEMS REPO (autocomplete catalog)
# =============================================================================
info "Writing known_items repo..."

cat > lib/repo/known_items_repo.dart <<'DART'
import '../model/known_item.dart';

abstract class KnownItemsRepo {
  Future<void> init();
  List<KnownItem> getAll();
  List<KnownItem> search(String query, {int limit = 5});
  Future<void> upsert(KnownItem item);
  Future<void> clear();
}
DART

cat > lib/repo/known_items_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../model/known_item.dart';
import 'known_items_repo.dart';
import 'seed_data.dart';

class KnownItemsRepoImpl implements KnownItemsRepo {
  // Device-local: shared across users on this device.
  static const _boxName = 'known_items';
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  List<KnownItem> getAll() => _box.values
      .map((v) => KnownItem.fromMap(Map<String, dynamic>.from(v as Map)))
      .toList();

  @override
  List<KnownItem> search(String query, {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = getAll()
        .where((k) => k.nameLower.contains(q))
        .toList();
    // Prioritize: startsWith first, then contains; then by lastSeen desc
    results.sort((a, b) {
      final aStarts = a.nameLower.startsWith(q);
      final bStarts = b.nameLower.startsWith(q);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return b.lastSeen.compareTo(a.lastSeen);
    });
    return results.take(limit).toList();
  }

  @override
  Future<void> upsert(KnownItem item) async {
    await _box.put(item.nameLower, item.toMap());
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> seedFromDefaults() async {
    for (final m in SeedData.knownItems) {
      await _box.put(m['nameLower'], m);
    }
  }
}
DART

ok "Known items repo written."

# =============================================================================
# 10. AUTH REPO (FirebaseAuth wrapper)
# =============================================================================
info "Writing auth repo..."

cat > lib/repo/auth_repo.dart <<'DART'
import 'package:firebase_auth/firebase_auth.dart';

/// Auth contract used by AuthVM.
abstract class AuthRepo {
  Stream<User?> get authStateChanges();
  User? get currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<User?> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);
  Future<void> updateDisplayName(String name);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
  Future<void> deleteAccount();
}
DART

cat > lib/repo/auth_repo_impl.dart <<'DART'
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
    }
    return _auth.currentUser;
  }

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
}
DART

ok "Auth repo written."

# =============================================================================
# 11. FIRESTORE IMPLEMENTATIONS
# =============================================================================
info "Writing Firestore repo implementations..."

# ---- profile repo (Firestore only — no Hive impl needed) ------------------
cat > lib/repo/profile_repo.dart <<'DART'
import '../model/user_profile.dart';

abstract class ProfileRepo {
  Future<UserProfile?> get(String uid);
  Future<void> save(String uid, UserProfile profile);
  Future<void> update(String uid, Map<String, dynamic> fields);
  Future<void> delete(String uid);
}
DART

cat > lib/repo/profile_repo_impl.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/user_profile.dart';
import 'profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  final _fs = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.meta)
      .doc(AppStrings.profileDoc);

  @override
  Future<UserProfile?> get(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data() ?? {});
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> update(String uid, Map<String, dynamic> fields) async {
    await _doc(uid).set(fields, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid) async {
    await _doc(uid).delete();
  }
}
DART

# ---- Firestore pantry impl -------------------------------------------------
cat > lib/repo/pantry_repo_firebase_impl.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';

/// Firestore-backed pantry repo (per-user).
/// Uses Firestore's built-in offline persistence to work offline too.
/// Reads still come from a synced in-memory cache populated by SyncService.
class PantryRepoFirebaseImpl implements PantryRepo {
  final String uid;
  final PantryRepo cache; // Hive-backed local cache
  PantryRepoFirebaseImpl({required this.uid, required this.cache});

  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.pantryCol);

  @override
  Future<void> init() async => cache.init();

  @override
  List<PantryItem> getAll() => cache.getAll();

  @override
  PantryItem? getById(String id) => cache.getById(id);

  @override
  Future<void> add(PantryItem item) async {
    await cache.add(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    await cache.addRaw(map);
    await _col.doc(map['id'] as String).set(map);
  }

  @override
  Future<void> update(PantryItem item) async {
    await cache.update(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await cache.delete(id);
    await _col.doc(id).delete();
  }

  @override
  Future<void> clear() async {
    await cache.clear();
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
DART

# ---- Firestore shopping impl ----------------------------------------------
cat > lib/repo/shopping_repo_firebase_impl.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';

class ShoppingRepoFirebaseImpl implements ShoppingRepo {
  final String uid;
  final ShoppingRepo cache;
  ShoppingRepoFirebaseImpl({required this.uid, required this.cache});
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.shoppingCol);

  @override
  Future<void> init() async => cache.init();

  @override
  List<ShoppingItem> getAll() => cache.getAll();

  @override
  Future<void> add(ShoppingItem item) async {
    await cache.add(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> addRaw(Map<String, dynamic> map) async {
    await cache.addRaw(map);
    await _col.doc(map['id'] as String).set(map);
  }

  @override
  Future<void> update(ShoppingItem item) async {
    await cache.update(item);
    await _col.doc(item.id).set(item.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await cache.delete(id);
    await _col.doc(id).delete();
  }

  @override
  Future<void> clear() async {
    await cache.clear();
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
DART

# ---- Firestore favorites impl ---------------------------------------------
cat > lib/repo/favorites_repo_firebase_impl.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import 'favorites_repo.dart';

class FavoritesRepoFirebaseImpl implements FavoritesRepo {
  final String uid;
  final FavoritesRepo cache;
  FavoritesRepoFirebaseImpl({required this.uid, required this.cache});
  final _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.favoritesCol);

  @override
  Future<void> init() async => cache.init();

  @override
  Set<String> getAll() => cache.getAll();

  @override
  bool isFavorite(String recipeId) => cache.isFavorite(recipeId);

  @override
  Future<void> toggle(String recipeId) async {
    final was = cache.isFavorite(recipeId);
    await cache.toggle(recipeId);
    if (was) {
      await _col.doc(recipeId).delete();
    } else {
      await _col.doc(recipeId).set({'favorite': true});
    }
  }

  @override
  Future<void> setAll(Set<String> ids) async {
    await cache.setAll(ids);
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
    for (final id in ids) {
      await _col.doc(id).set({'favorite': true});
    }
  }

  @override
  Future<void> clear() async {
    await cache.clear();
    final snap = await _col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
DART

ok "Firestore repo implementations written."

# =============================================================================
# 12. SERVICES LOCATOR + SYNC SERVICE
# =============================================================================
info "Writing Services locator + SyncService..."

# ---- Services (dynamic based on auth state) --------------------------------
cat > lib/repo/services.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_repo.dart';
import 'auth_repo_impl.dart';
import 'favorites_repo.dart';
import 'favorites_repo_firebase_impl.dart';
import 'favorites_repo_impl.dart';
import 'known_items_repo.dart';
import 'known_items_repo_impl.dart';
import 'pantry_repo.dart';
import 'pantry_repo_firebase_impl.dart';
import 'pantry_repo_impl.dart';
import 'profile_repo.dart';
import 'profile_repo_impl.dart';
import 'recipe_repo.dart';
import 'recipe_repo_impl.dart';
import 'settings_repo.dart';
import 'settings_repo_impl.dart';
import 'shopping_repo.dart';
import 'shopping_repo_firebase_impl.dart';
import 'shopping_repo_impl.dart';

/// Service locator. Repos are re-created when auth state changes so they
/// switch between guest (Hive-only) and logged-in (Hive + Firestore).
class Services {
  Services._();

  // Always available
  static late final AuthRepo auth;
  static late final SettingsRepo settings;
  static late final RecipeRepo recipes;
  static late final KnownItemsRepo knownItems;
  static late final ProfileRepo profile;

  // Rebuilt on login/logout
  static late PantryRepo pantry;
  static late ShoppingRepo shopping;
  static late FavoritesRepo favorites;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    auth = AuthRepoImpl();
    profile = ProfileRepoImpl();
    recipes = RecipeRepoImpl();

    final s = SettingsRepoImpl();
    await s.init();
    settings = s;

    final k = KnownItemsRepoImpl();
    await k.init();
    if (!settings.knownItemsSeeded) {
      await k.seedFromDefaults();
      await settings.markKnownItemsSeeded();
    }
    knownItems = k;

    // Initialize data repos for the current auth state
    final user = FirebaseAuth.instance.currentUser;
    await bindUserRepos(user?.uid);

    // Seed guest data on first launch — so app is usable before signup
    if (user == null && !settings.seeded) {
      final p = pantry as PantryRepoImpl;
      final sh = shopping as ShoppingRepoImpl;
      final f = favorites as FavoritesRepoImpl;
      await p.seedFromDefaults();
      await sh.seedFromDefaults();
      await f.seedFromDefaults();
      await settings.markSeeded();
    }
  }

  /// Called on login, logout, and app startup. Rebinds all per-user repos.
  static Future<void> bindUserRepos(String? uid) async {
    final localPantry = PantryRepoImpl(uid: uid);
    final localShopping = ShoppingRepoImpl(uid: uid);
    final localFavorites = FavoritesRepoImpl(uid: uid);

    await Future.wait([
      localPantry.init(),
      localShopping.init(),
      localFavorites.init(),
    ]);

    if (uid == null) {
      pantry = localPantry;
      shopping = localShopping;
      favorites = localFavorites;
    } else {
      pantry = PantryRepoFirebaseImpl(uid: uid, cache: localPantry);
      shopping = ShoppingRepoFirebaseImpl(uid: uid, cache: localShopping);
      favorites =
          FavoritesRepoFirebaseImpl(uid: uid, cache: localFavorites);
    }
  }

  /// Wipe all data + re-seed the current binding.
  /// Used by the "Reset Demo Data" button.
  static Future<void> resetAndReseedCurrent() async {
    await pantry.clear();
    await shopping.clear();
    await favorites.clear();

    // Re-seed the local cache
    final user = FirebaseAuth.instance.currentUser;
    final localPantry = PantryRepoImpl(uid: user?.uid);
    final localShopping = ShoppingRepoImpl(uid: user?.uid);
    final localFavorites = FavoritesRepoImpl(uid: user?.uid);
    await Future.wait([
      localPantry.init(),
      localShopping.init(),
      localFavorites.init(),
    ]);
    await localPantry.seedFromDefaults();
    await localShopping.seedFromDefaults();
    await localFavorites.seedFromDefaults();

    // If logged in, also push seed to Firestore
    if (user != null) {
      for (final m in await _collectPantry(localPantry)) {
        await pantry.addRaw(m);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> _collectPantry(
      PantryRepoImpl p) async {
    return p.getAll().map((i) => i.toMap()).toList();
  }
}
DART

# ---- SyncService — Hive <-> Firestore migration on login/logout -----------
cat > lib/repo/sync_service.dart <<'DART'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import 'pantry_repo_impl.dart';
import 'shopping_repo_impl.dart';
import 'favorites_repo_impl.dart';
import 'services.dart';

/// Handles two flows:
/// 1. First login (Hive → Firestore): user was using app as guest, now signs up.
///    Guest data uploaded to Firestore.
/// 2. Later logins (Firestore → Hive): user signs in on new device or after
///    reinstall. Firestore is source of truth, download to Hive cache.
class SyncService {
  final _fs = FirebaseFirestore.instance;

  /// Upload local (guest) Hive data to Firestore. Used on first signup.
  Future<void> uploadGuestToCloud(String uid) async {
    final guestPantry = PantryRepoImpl(uid: null);
    final guestShopping = ShoppingRepoImpl(uid: null);
    final guestFavorites = FavoritesRepoImpl(uid: null);
    await Future.wait([
      guestPantry.init(),
      guestShopping.init(),
      guestFavorites.init(),
    ]);

    // Pantry
    for (final item in guestPantry.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.pantryCol)
          .doc(item.id)
          .set(item.toMap());
    }
    // Shopping
    for (final item in guestShopping.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.shoppingCol)
          .doc(item.id)
          .set(item.toMap());
    }
    // Favorites
    for (final rid in guestFavorites.getAll()) {
      await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(AppStrings.favoritesCol)
          .doc(rid)
          .set({'favorite': true});
    }

    // Copy guest data into the user's Hive namespace (so we have a warm cache)
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);
    for (final item in guestPantry.getAll()) {
      await userPantry.add(item);
    }
    for (final item in guestShopping.getAll()) {
      await userShopping.add(item);
    }
    for (final rid in guestFavorites.getAll()) {
      await userFavorites.toggle(rid);
    }
    // Clear guest data now that it's migrated
    await guestPantry.clear();
    await guestShopping.clear();
    await guestFavorites.clear();
  }

  /// Download Firestore data into the user's Hive cache.
  /// Called on login, before repos are rebound.
  Future<void> downloadCloudToLocal(String uid) async {
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);

    // Pantry
    final pantrySnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.pantryCol)
        .get();
    if (pantrySnap.docs.isNotEmpty) {
      await userPantry.clear();
      for (final d in pantrySnap.docs) {
        await userPantry.addRaw(Map<String, dynamic>.from(d.data()));
      }
    }

    // Shopping
    final shopSnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.shoppingCol)
        .get();
    if (shopSnap.docs.isNotEmpty) {
      await userShopping.clear();
      for (final d in shopSnap.docs) {
        await userShopping.addRaw(Map<String, dynamic>.from(d.data()));
      }
    }

    // Favorites
    final favSnap = await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.favoritesCol)
        .get();
    if (favSnap.docs.isNotEmpty) {
      final ids = favSnap.docs.map((d) => d.id).toSet();
      await userFavorites.setAll(ids);
    }
  }

  /// Called after signup: check whether the user's cloud is empty; if so,
  /// upload local guest data. Otherwise, download cloud to local.
  Future<void> onLogin(String uid, {required bool wasSignUp}) async {
    if (wasSignUp) {
      await uploadGuestToCloud(uid);
    } else {
      await downloadCloudToLocal(uid);
    }
    await Services.bindUserRepos(uid);
  }

  /// Called on logout: clear guest cache, don't touch user data.
  Future<void> onLogout() async {
    await Services.bindUserRepos(null);
  }

  /// Called on delete account: wipe Firestore + user's Hive namespace.
  Future<void> deleteAllUserData(String uid) async {
    // Firestore
    for (final col in [
      AppStrings.pantryCol,
      AppStrings.shoppingCol,
      AppStrings.favoritesCol,
    ]) {
      final snap = await _fs
          .collection(AppStrings.usersCol)
          .doc(uid)
          .collection(col)
          .get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    }
    // Profile
    await _fs
        .collection(AppStrings.usersCol)
        .doc(uid)
        .collection(AppStrings.meta)
        .doc(AppStrings.profileDoc)
        .delete();

    // Hive
    final userPantry = PantryRepoImpl(uid: uid);
    final userShopping = ShoppingRepoImpl(uid: uid);
    final userFavorites = FavoritesRepoImpl(uid: uid);
    await Future.wait([
      userPantry.init(),
      userShopping.init(),
      userFavorites.init(),
    ]);
    await userPantry.clear();
    await userShopping.clear();
    await userFavorites.clear();
  }
}

final syncService = SyncService();
DART

ok "Services + SyncService written."

# =============================================================================
# 13. THEME
# =============================================================================
info "Writing theme..."

cat > lib/view/theme/theme_controller.dart <<'DART'
import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeController =
    ValueNotifier<ThemeMode>(ThemeMode.light);
DART

cat > lib/view/theme/app_theme.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    );
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightCard,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primaryDark,
          fontSize: 24, fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.lightTextMuted, fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    );
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.darkCard,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primary,
          fontSize: 24, fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.darkTextMuted, fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
DART

ok "Theme written."

# =============================================================================
# 14. MAIN.DART with Firebase init
# =============================================================================
info "Writing main.dart..."

cat > lib/main.dart <<'DART'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'repo/services.dart';
import 'view/screens/auth/auth_gate.dart';
import 'view/theme/app_theme.dart';
import 'view/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Services.init();
  themeController.value =
      Services.settings.darkMode ? ThemeMode.dark : ThemeMode.light;
  runApp(const ShelfLifeApp());
}

class ShelfLifeApp extends StatelessWidget {
  const ShelfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'ShelfLife',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}
DART

ok "main.dart written."

# =============================================================================
# 15. VIEWMODELS
# =============================================================================
info "Writing viewmodels..."

# ---- auth_vm --------------------------------------------------------------
cat > lib/viewmodel/auth_vm.dart <<'DART'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/user_profile.dart';
import '../repo/services.dart';
import '../repo/sync_service.dart';
import 'pantry_vm.dart';
import 'shopping_vm.dart';
import 'recipe_vm.dart';
import 'home_vm.dart';

class AuthVM extends ChangeNotifier {
  User? _user;
  bool _busy = false;
  String? _error;
  UserProfile? _profile;

  User? get currentUser => _user;
  bool get busy => _busy;
  String? get error => _error;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _user != null;

  Stream<User?> get authStateChanges => Services.auth.authStateChanges;

  AuthVM() {
    _user = Services.auth.currentUser;
    Services.auth.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
      if (u != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      _profile = await Services.profile.get(_user!.uid);
      notifyListeners();
    } catch (_) {
      // Non-fatal
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthdate,
    String? gender,
    List<String> dietaryPrefs = const [],
    List<String> allergies = const [],
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await Services.auth.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (u == null) throw Exception('Signup returned null user');
      _user = u;

      // Save profile
      final prof = UserProfile(
        displayName: displayName,
        email: email,
        birthdate: birthdate,
        gender: gender,
        dietaryPrefs: dietaryPrefs,
        allergies: allergies,
        darkMode: Services.settings.darkMode,
      );
      await Services.profile.save(u.uid, prof);
      _profile = prof;

      // Upload guest Hive data to cloud, rebind repos
      await syncService.onLogin(u.uid, wasSignUp: true);
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();

      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await Services.auth.signIn(email: email, password: password);
      if (u == null) throw Exception('Signin returned null user');
      _user = u;

      await syncService.onLogin(u.uid, wasSignUp: false);
      await _loadProfile();
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();

      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await Services.auth.sendPasswordReset(email);
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await Services.auth.signOut();
    await syncService.onLogout();
    _profile = null;
    // notify — repos have been rebound
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    homeVM.notifyListeners();
  }

  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _user!.uid;
      await syncService.deleteAllUserData(uid);
      await Services.auth.deleteAccount();
      await syncService.onLogout();
      _profile = null;
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_user == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await Services.auth.updatePassword(newPassword);
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveProfile(UserProfile updated) async {
    if (_user == null) return;
    await Services.profile.save(_user!.uid, updated);
    _profile = updated;
    notifyListeners();
  }

  String _prettyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to do this.';
      default:
        return e.message ?? e.code;
    }
  }
}

final authVM = AuthVM();
DART

# ---- pantry_vm (with expiring counts fixed for nullable expiry) -----------
cat > lib/viewmodel/pantry_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/enums.dart';
import '../model/known_item.dart';
import '../model/pantry_item.dart';
import '../repo/services.dart';

class PantryVM extends ChangeNotifier {
  String _filter = 'All';
  String _query = '';

  String get filter => _filter;
  String get query => _query;

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  List<PantryItem> get all => Services.pantry.getAll();
  List<PantryItem> get active =>
      all.where((i) => i.status == ItemStatus.active).toList();
  List<PantryItem> get finished =>
      all.where((i) => i.status == ItemStatus.finished).toList();

  List<PantryItem> get filtered {
    List<PantryItem> items;
    switch (_filter) {
      case 'All':
        items = active;
        break;
      case 'Favorites':
        items = active.where((i) => i.favorite).toList();
        break;
      case 'Finished':
        items = finished;
        break;
      default:
        items = active.where((i) => i.category == _filter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q) ||
              (i.notes ?? '').toLowerCase().contains(q))
          .toList();
    }
    // Sort by expiry (no-expiry items sink to bottom via daysUntilExpiry sentinel)
    items.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return items;
  }

  /// Use First — only items WITH expiry (excludes no-expiry per bug fix #8)
  List<PantryItem> get useFirst {
    final list =
        active.where((i) => i.hasExpiry).toList();
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  int get totalActiveCount => active.length;

  /// Excludes no-expiry items
  int get expiringSoonCount => active
      .where((i) => i.hasExpiry && i.daysUntilExpiry <= 2)
      .length;

  Future<void> add(PantryItem item) async {
    await Services.pantry.add(item);
    // Autocomplete catalog: remember this item so it suggests later
    await Services.knownItems.upsert(KnownItem(
      nameLower: item.name.trim().toLowerCase(),
      name: item.name.trim(),
      category: item.category,
      imageAsset: item.imageAsset,
      imageUrl: item.imageUrl,
      defaultUnit: item.unitCode,
      lastSeen: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> update(PantryItem item) async {
    await Services.pantry.update(item);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await Services.pantry.delete(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(PantryItem item) async {
    await Services.pantry.update(item.copyWith(favorite: !item.favorite));
    notifyListeners();
  }

  Future<void> markFinished(PantryItem item) async {
    await Services.pantry
        .update(item.copyWith(status: ItemStatus.finished));
    notifyListeners();
  }

  Future<void> markActive(PantryItem item) async {
    await Services.pantry
        .update(item.copyWith(status: ItemStatus.active));
    notifyListeners();
  }

  Future<void> bumpQuantity(PantryItem existing, double amount) async {
    await Services.pantry
        .update(existing.copyWith(quantity: existing.quantity + amount));
    notifyListeners();
  }

  PantryItem? findDuplicate(String name) {
    final n = name.trim().toLowerCase();
    for (final i in active) {
      if (i.name.trim().toLowerCase() == n) return i;
    }
    return null;
  }
}

final pantryVM = PantryVM();
DART

# ---- shopping_vm ----------------------------------------------------------
cat > lib/viewmodel/shopping_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/shopping_item.dart';
import '../repo/services.dart';
import 'pantry_vm.dart';

class ShoppingVM extends ChangeNotifier {
  List<ShoppingItem> get all => Services.shopping.getAll();
  int get checkedCount => all.where((i) => i.checked).length;

  Future<void> add(ShoppingItem item) async {
    await Services.shopping.add(item);
    notifyListeners();
  }

  Future<void> update(ShoppingItem item) async {
    await Services.shopping.update(item);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await Services.shopping.delete(id);
    notifyListeners();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    item.checked = !item.checked;
    await Services.shopping.update(item);
    notifyListeners();
  }

  /// Returns the moved items so callers can offer UNDO.
  Future<List<ShoppingItem>> moveCheckedToPantry() async {
    final checked = all.where((i) => i.checked).toList();
    final now = DateTime.now();
    for (final s in checked) {
      final p = PantryItem(
        id: 'p_${now.microsecondsSinceEpoch}_${s.id}',
        name: s.name,
        category: 'Other',
        quantity: 1,
        unitCode: 'unit',
        expiryDate: null, // v5: no default expiry
        addedDate: now,
        purchaseDate: now,
      );
      await Services.pantry.add(p);
      await Services.shopping.delete(s.id);
    }
    pantryVM.notifyListeners();
    notifyListeners();
    return checked;
  }

  /// For UNDO of moveCheckedToPantry: put items back.
  Future<void> restoreCheckedToShopping(
      List<ShoppingItem> items, List<String> pantryIdsToRemove) async {
    for (final s in items) {
      await Services.shopping.add(s);
    }
    for (final id in pantryIdsToRemove) {
      await Services.pantry.delete(id);
    }
    pantryVM.notifyListeners();
    notifyListeners();
  }

  Future<void> addIngredient(String name, String? note) async {
    await add(ShoppingItem(
      id: 's_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      note: note,
    ));
  }
}

final shoppingVM = ShoppingVM();
DART

# ---- recipe_vm ------------------------------------------------------------
cat > lib/viewmodel/recipe_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/recipe.dart';
import '../repo/services.dart';

class RecipeVM extends ChangeNotifier {
  String _query = '';
  int? _maxMinutes;

  String get query => _query;
  int? get maxMinutes => _maxMinutes;
  bool get isSearching => _query.trim().isNotEmpty || _maxMinutes != null;

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setMaxMinutes(int? m) {
    _maxMinutes = m;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _maxMinutes = null;
    notifyListeners();
  }

  List<Recipe> get all => Services.recipes.getAll();
  List<Recipe> get useFirst => Services.recipes.getUseFirst();
  List<Recipe> get matches => Services.recipes.getMatches();

  List<Recipe> get favorites {
    final favIds = Services.favorites.getAll();
    return all.where((r) => favIds.contains(r.id)).toList();
  }

  bool isFavorite(String recipeId) => Services.favorites.isFavorite(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    await Services.favorites.toggle(recipeId);
    notifyListeners();
  }

  List<Recipe> get searchResults {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (_maxMinutes != null && r.timeMinutes > _maxMinutes!) return false;
      if (q.isEmpty) return true;
      if (r.title.toLowerCase().contains(q)) return true;
      for (final ing in r.ingredients) {
        if (ing.toLowerCase().contains(q)) return true;
      }
      for (final tag in r.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }
}

final recipeVM = RecipeVM();
DART

# ---- profile_vm ------------------------------------------------------------
cat > lib/viewmodel/profile_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repo/services.dart';
import '../view/theme/theme_controller.dart';
import 'auth_vm.dart';

class ProfileVM extends ChangeNotifier {
  bool get darkMode => Services.settings.darkMode;

  Future<void> setDarkMode(bool v) async {
    await Services.settings.setDarkMode(v);
    themeController.value = v ? ThemeMode.dark : ThemeMode.light;
    // Persist to Firestore profile too
    if (authVM.currentUser != null && authVM.profile != null) {
      await authVM.saveProfile(authVM.profile!.copyWith(darkMode: v));
    }
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await Services.resetAndReseedCurrent();
    notifyListeners();
  }
}

final profileVM = ProfileVM();
DART

# ---- home_vm ---------------------------------------------------------------
cat > lib/viewmodel/home_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../repo/services.dart';

class HomeVM extends ChangeNotifier {
  List<PantryItem> get activeItems =>
      Services.pantry.getAll().where((i) => i.isActive).toList();

  int get totalItems => activeItems.length;

  /// Only items WITH expiry (bug fix #8)
  int get expiringSoon => activeItems
      .where((i) => i.hasExpiry && i.daysUntilExpiry <= 2)
      .length;

  /// Only items WITH expiry
  List<PantryItem> get useFirst {
    final list = activeItems.where((i) => i.hasExpiry).toList();
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  /// Real wasted % — bug fix #5
  /// Uses (finished + expired active) / (total ever) over pantry lifetime.
  double get wastedPercent {
    final all = Services.pantry.getAll();
    if (all.isEmpty) return 0.0;
    final finished = all.where((i) => i.isFinished).length;
    final expiredActive = all
        .where((i) => i.isActive && i.hasExpiry && i.daysUntilExpiry < 0)
        .length;
    return (finished + expiredActive) / all.length * 100.0;
  }

  /// Waste-reduction trend — synthetic for now (real data needs history).
  /// Uses actual waste % as the latest data point.
  List<double> get wasteTrend {
    final current = wastedPercent / 10.0;
    return [7.0, 6.0, 4.0, current.clamp(1.0, 10.0)];
  }

  /// Real category distribution — bug fix #4
  /// Returns map of category -> count (only for categories with items).
  Map<String, int> get categoryDistribution {
    final map = <String, int>{};
    for (final i in activeItems) {
      map[i.category] = (map[i.category] ?? 0) + 1;
    }
    return map;
  }

  List<Map<String, String>> get suggestions {
    final result = <Map<String, String>>[];
    final expired = activeItems
        .where((i) => i.hasExpiry && i.daysUntilExpiry <= 0)
        .take(2)
        .toList();
    final lowStock = activeItems
        .where((i) =>
            i.hasExpiry &&
            i.daysUntilExpiry > 0 &&
            i.daysUntilExpiry <= 3)
        .take(1)
        .toList();
    for (final i in expired) {
      result.add({'name': i.name, 'reason': 'Expired', 'type': 'expired'});
    }
    for (final i in lowStock) {
      result.add({
        'name': i.name,
        'reason':
            'Expiring in ${i.daysUntilExpiry} day${i.daysUntilExpiry == 1 ? '' : 's'}',
        'type': 'low',
      });
    }
    return result;
  }
}

final homeVM = HomeVM();
DART

ok "ViewModels written."

# =============================================================================
# 16. SHARED WIDGETS
# =============================================================================
info "Writing shared widgets..."

cat > lib/view/widgets/vm_listener.dart <<'DART'
import 'package:flutter/material.dart';

class VMListener extends StatelessWidget {
  final Listenable listenable;
  final Widget Function(BuildContext) builder;
  const VMListener({
    super.key,
    required this.listenable,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (ctx, _) => builder(ctx),
    );
  }
}
DART

cat > lib/view/widgets/app_logo.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';

Future<bool> _assetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

class AppLogoText extends StatelessWidget {
  final double height;
  const AppLogoText({super.key, this.height = 32});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists('assets/logo/shelflife_logo.svg'),
      builder: (_, snap) {
        if (snap.data == true) {
          return SvgPicture.asset(
            'assets/logo/shelflife_logo.svg',
            height: height,
          );
        }
        return Text('ShelfLife',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: height * 0.75,
              fontWeight: FontWeight.w800,
            ));
      },
    );
  }
}

class AppLogoIcon extends StatelessWidget {
  final double size;
  const AppLogoIcon({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists('assets/logo/shelflife_icon.svg'),
      builder: (_, snap) {
        if (snap.data == true) {
          return SvgPicture.asset(
            'assets/logo/shelflife_icon.svg',
            width: size, height: size,
          );
        }
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.shopping_basket_outlined,
            color: Colors.white,
            size: size * 0.55,
          ),
        );
      },
    );
  }
}
DART

cat > lib/view/widgets/main_app_bar.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../screens/misc/notifications_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import 'app_logo.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primary : AppColors.primaryDark;
    return AppBar(
      automaticallyImplyLeading: false,
      title: const AppLogoText(height: 30),
      leading: IconButton(
        icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
          );
        },
      ),
      actions: [
        IconButton(
          icon:
              Icon(Icons.notifications_none, color: AppColors.textPri(context)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }
}
DART

cat > lib/view/widgets/onboarding_header.dart <<'DART'
import 'package:flutter/material.dart';
import 'app_logo.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          AppLogoIcon(size: 36),
          SizedBox(width: 8),
          AppLogoText(height: 30),
        ],
      ),
    );
  }
}
DART

cat > lib/view/widgets/bottom_nav.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../screens/main/main_shell.dart';

class ShelfBottomNav extends StatelessWidget {
  final int currentIndex;
  const ShelfBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainShell(initialIndex: index),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(
                  context, 1, Icons.kitchen_outlined, Icons.kitchen, 'Pantry'),
              _addButton(context),
              _navItem(context, 3, Icons.receipt_long_outlined,
                  Icons.receipt_long, 'Recipe'),
              _navItem(
                  context, 4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon,
      IconData iconActive, String label) {
    final selected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected)
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconActive, color: Colors.white, size: 20),
                )
              else
                Icon(icon, color: AppColors.textPri(context), size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPri(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    final selected = currentIndex == 2;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeeper,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeeper.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 2),
              Text('Add',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPri(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
DART

cat > lib/view/widgets/pantry_item_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/enums.dart';
import '../../model/pantry_item.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final bool compact;
  final bool showMenu;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const PantryItemCard({
    super.key,
    required this.item,
    this.compact = false,
    this.showMenu = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  Color get _statusColor {
    if (item.isFinished) return Colors.grey;
    switch (item.expiryStatus) {
      case ExpiryStatus.expired:  return AppColors.danger;
      case ExpiryStatus.soon:     return AppColors.warning;
      case ExpiryStatus.safe:     return AppColors.safe;
      case ExpiryStatus.noExpiry: return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final greyed = item.isFinished;
    return Opacity(
      opacity: greyed ? 0.55 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: _statusColor, width: 5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _itemImage(context),
              const SizedBox(width: 12),
              Expanded(child: _itemBody(context)),
              if (onFavoriteToggle != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    item.favorite ? Icons.favorite : Icons.favorite_border,
                    color: item.favorite
                        ? AppColors.danger
                        : AppColors.textMut(context),
                    size: 22,
                  ),
                  onPressed: onFavoriteToggle,
                ),
              if (showMenu)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.more_vert,
                      color: AppColors.textSec(context)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 60, height: 60,
        color: AppColors.chipBg(context),
        child: item.imageUrl != null
            ? Image.network(item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(context))
            : item.imageAsset != null
                ? Image.asset(item.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(context))
                : _imageFallback(context),
      ),
    );
  }

  Widget _imageFallback(BuildContext context) => Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.textMut(context), size: 24),
      );

  Widget _itemBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPri(context),
                  decoration:
                      item.isFinished ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (compact && item.hasExpiry)
              Text(
                _daysLabel(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        if (!compact)
          Text(
            '${item.category} • ${item.quantityLabel}',
            style: TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 4),
        if (!compact)
          Row(
            children: [
              Icon(_statusIcon(), color: _statusColor, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.isFinished ? 'Finished' : item.expiryLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            item.expiryLabel,
            style: TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        if (item.hasExpiry && !item.isFinished) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: AppColors.chipBg(context),
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            ),
          ),
        ],
      ],
    );
  }

  IconData _statusIcon() {
    if (item.isFinished) return Icons.check_circle;
    switch (item.expiryStatus) {
      case ExpiryStatus.expired:  return Icons.error_outline;
      case ExpiryStatus.soon:     return Icons.calendar_today;
      case ExpiryStatus.safe:     return Icons.check_circle_outline;
      case ExpiryStatus.noExpiry: return Icons.all_inclusive;
    }
  }

  String _daysLabel() {
    if (item.isFinished) return 'Done';
    if (!item.hasExpiry) return '—';
    final d = item.daysUntilExpiry;
    if (d < 0) return 'Expired';
    if (d == 0) return 'Today';
    if (d == 1) return '1 Day';
    return '$d Days';
  }
}
DART

# ---- ItemNameField (autocomplete) — used in Add + Edit --------------------
cat > lib/view/widgets/item_name_field.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/known_item.dart';
import '../../repo/services.dart';

/// Text field with dropdown autocomplete based on the KnownItems catalog.
/// When user selects a suggestion, callback fires with the full KnownItem
/// so the caller can prefill category, image, unit, etc.
class ItemNameField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(KnownItem picked)? onPicked;
  final String? hintText;
  final Widget? prefixIcon;
  final bool autofocus;
  final InputDecoration? decoration;

  const ItemNameField({
    super.key,
    required this.controller,
    this.onPicked,
    this.hintText = 'e.g. Fresh Chicken Breast',
    this.prefixIcon,
    this.autofocus = false,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<KnownItem>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (val) {
        return Services.knownItems.search(val.text, limit: 5);
      },
      displayStringForOption: (opt) => opt.name,
      fieldViewBuilder: (ctx, textCtrl, focusNode, onSubmit) {
        // Sync external controller with the Autocomplete's controller
        textCtrl.text = controller.text;
        textCtrl.selection =
            TextSelection.collapsed(offset: textCtrl.text.length);
        textCtrl.addListener(() {
          if (controller.text != textCtrl.text) {
            controller.text = textCtrl.text;
          }
        });
        controller.addListener(() {
          if (textCtrl.text != controller.text) {
            textCtrl.text = controller.text;
          }
        });
        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          autofocus: autofocus,
          decoration: (decoration ??
                  InputDecoration(
                    hintText: hintText,
                    prefixIcon: prefixIcon ??
                        const Icon(Icons.shopping_basket_outlined),
                  ))
              .copyWith(
            suffixIcon: textCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      textCtrl.clear();
                      controller.clear();
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 240, maxWidth: 400),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 40, height: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: opt.imageAsset != null
                            ? Image.asset(opt.imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.chipBg(ctx),
                                      child: Icon(Icons.image_not_supported,
                                          color: AppColors.textMut(ctx),
                                          size: 16),
                                    ))
                            : Container(
                                color: AppColors.chipBg(ctx),
                                child: Icon(Icons.shopping_basket_outlined,
                                    color: AppColors.textMut(ctx), size: 18),
                              ),
                      ),
                    ),
                    title: Text(opt.name,
                        style: TextStyle(
                            color: AppColors.textPri(ctx),
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(opt.category,
                        style: TextStyle(
                            color: AppColors.textSec(ctx), fontSize: 12)),
                    onTap: () {
                      onSelected(opt);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (opt) {
        controller.text = opt.name;
        onPicked?.call(opt);
      },
    );
  }
}
DART

ok "Widgets written."

# =============================================================================
# 17. SPLASH + AUTHGATE + LOGIN + FORGOT PASSWORD + NOTIFICATIONS
# =============================================================================
info "Writing splash, auth gate, login..."

# ---- Splash (transitions to AuthGate) ------------------------------------
cat > lib/view/screens/misc/splash_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogoIcon(size: 96),
            const SizedBox(height: 16),
            const AppLogoText(height: 40),
            const SizedBox(height: 8),
            Text('Freshness at your fingertips',
                style: TextStyle(
                    color: AppColors.textSec(context), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
DART

# ---- AuthGate -------------------------------------------------------------
cat > lib/view/screens/auth/auth_gate.dart <<'DART'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';
import '../main/main_shell.dart';
import 'login_screen.dart';

/// Watches authStateChanges and routes to Login or MainShell accordingly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }
        if (snap.hasData) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
DART

# ---- Notifications --------------------------------------------------------
cat > lib/view/screens/misc/notifications_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primary : AppColors.primaryDark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text('Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          _row(context, Icons.warning_amber_rounded, AppColors.danger,
              'Yogurt is expiring tomorrow', '2h ago'),
          _row(context, Icons.shopping_cart_outlined, AppColors.primary,
              '3 items added to shopping list', '4h ago'),
          _row(context, Icons.restaurant, AppColors.primary,
              '5 recipe matches updated', '1d ago'),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, Color color, String title,
      String when) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(when,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSec(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

# ---- Login (with real Firebase auth, loading, error, forgot pw) ------------
cat > lib/view/screens/auth/login_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import '../onboarding/signup_step1_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _showPassword = false;

  Future<bool> _bgExists() async {
    try {
      await rootBundle.load('assets/onboarding/login_bg.png');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _showSocialToast(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider Sign-In coming in v5.1')),
    );
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _pwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    final ok = await authVM.signIn(
        email: _emailCtrl.text, password: _pwCtrl.text);
    if (!mounted) return;
    if (!ok && authVM.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error!)),
      );
    }
    // Navigation is handled by AuthGate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: VMListener(
          listenable: authVM,
          builder: (ctx) {
            final busy = authVM.busy;
            return SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<bool>(
                    future: _bgExists(),
                    builder: (_, snap) {
                      if (snap.data == true) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                          child: Image.asset(
                            'assets/onboarding/login_bg.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                        ),
                        child: const Center(child: AppLogoIcon(size: 80)),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const AppLogoText(height: 40),
                  const SizedBox(height: 6),
                  Text('Welcome back',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 14)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: !_showPassword,
                          enabled: !busy,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordScreen()),
                                    ),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: busy ? null : _login,
                          child: busy
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                )
                              : const Text('Log In'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppColors.divider(context))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or continue with',
                                  style: TextStyle(
                                    color: AppColors.textSec(context),
                                    fontSize: 12,
                                  )),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppColors.divider(context))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.g_mobiledata, size: 28),
                                label: const Text('Google'),
                                onPressed: busy
                                    ? null
                                    : () => _showSocialToast('Google'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.facebook,
                                    color: AppColors.facebookBlue),
                                label: const Text('Facebook'),
                                onPressed: busy
                                    ? null
                                    : () => _showSocialToast('Facebook'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                            GestureDetector(
                              onTap: busy
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const SignupStep1Screen()),
                                      ),
                              child: const Text('Sign up',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
DART

# ---- Forgot Password ------------------------------------------------------
cat > lib/view/screens/auth/forgot_password_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }
    final ok = await authVM.sendPasswordReset(_emailCtrl.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else if (authVM.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: authVM,
        builder: (ctx) {
          if (_sent) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.primaryDark, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text('Check your email',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    "We've sent a password reset link to ${_emailCtrl.text.trim()}. Follow the instructions to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSec(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            );
          }
          final busy = authVM.busy;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text('Forgot your password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 8),
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  style: TextStyle(
                    color: AppColors.textSec(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: busy ? null : _send,
                  child: busy
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send reset link'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
DART

ok "Splash + auth gate + login + forgot password + notifications written."

# =============================================================================
# 18. ONBOARDING / SIGNUP SCREENS (real Firebase signup at end)
# =============================================================================
info "Writing signup screens..."

# ---- signup_step1 ---------------------------------------------------------
cat > lib/view/screens/onboarding/signup_step1_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../widgets/onboarding_header.dart';
import 'signup_state.dart';
import 'signup_step2_screen.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});
  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _showPassword = false;
  DateTime? _birthdate;
  String? _gender;
  final _genderOptions = const ['Male', 'Female', 'Other', 'Prefer not'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<bool> _bgExists() async {
    try {
      await rootBundle.load('assets/onboarding/signup_pantry.png');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthdate',
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  void _continue() {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _pwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name, email, and password.')),
      );
      return;
    }
    if (_pwCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    signupState.name = _nameCtrl.text.trim();
    signupState.email = _emailCtrl.text.trim();
    signupState.password = _pwCtrl.text;
    signupState.birthdate = _birthdate;
    signupState.gender = _gender;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupStep2Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: _bgExists(),
              builder: (_, snap) {
                if (snap.data == true) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/onboarding/signup_pantry.png',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepDots(0),
                  const SizedBox(height: 14),
                  Text('Create your account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 4),
                  Text("We'll personalize your pantry experience.",
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 13)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Password (min 6 chars)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final narrow = c.maxWidth < 360;
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _birthdateField(),
                            const SizedBox(height: 10),
                            _genderField(),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _birthdateField()),
                          const SizedBox(width: 10),
                          Expanded(child: _genderField()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _birthdateField() {
    final text = _birthdate == null
        ? 'Birthdate'
        : DateFormat('MMM d, yyyy').format(_birthdate!);
    return InkWell(
      onTap: _pickBirthdate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.cake_outlined),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _birthdate == null
                ? AppColors.textMut(context)
                : AppColors.textPri(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _genderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      isExpanded: true,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.wc_outlined)),
      hint: Text('Gender',
          style: TextStyle(color: AppColors.textMut(context), fontSize: 14)),
      items: _genderOptions
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _stepDots(int active) {
    return Row(
      children: List.generate(3, (i) {
        final selected = i == active;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.divider(context),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
DART

# ---- signup state (temporary form data holder) -----------------------------
cat > lib/view/screens/onboarding/signup_state.dart <<'DART'
class SignupState {
  String? name;
  String? email;
  String? password;
  DateTime? birthdate;
  String? gender;
  List<String> dietaryPrefs = [];
  List<String> allergies = [];

  void reset() {
    name = null;
    email = null;
    password = null;
    birthdate = null;
    gender = null;
    dietaryPrefs = [];
    allergies = [];
  }
}

final signupState = SignupState();
DART

# ---- signup_step2 ---------------------------------------------------------
cat > lib/view/screens/onboarding/signup_step2_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_sizes.dart';
import '../../widgets/onboarding_header.dart';
import 'signup_state.dart';
import 'signup_step3_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});
  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  late Set<String> _picked;

  @override
  void initState() {
    super.initState();
    _picked = signupState.dietaryPrefs.toSet();
  }

  void _continue() {
    signupState.dietaryPrefs = _picked.toList();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupStep3Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepDots(1),
                  const SizedBox(height: 14),
                  Text('Dietary preferences',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 4),
                  Text('Select all that apply. Skip if none.',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 13)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: AppCategories.dietaryPrefs.map((pref) {
                      final selected = _picked.contains(pref);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _picked.remove(pref);
                          } else {
                            _picked.add(pref);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.chipBg(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(pref,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPri(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        signupState.dietaryPrefs = [];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupStep3Screen()),
                        );
                      },
                      child: Text('Skip',
                          style: TextStyle(
                              color: AppColors.textSec(context))),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDots(int active) {
    return Row(
      children: List.generate(3, (i) {
        final selected = i == active;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.divider(context),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
DART

# ---- signup_step3 (final — triggers Firebase signup) ----------------------
cat > lib/view/screens/onboarding/signup_step3_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/vm_listener.dart';
import 'signup_state.dart';

class SignupStep3Screen extends StatefulWidget {
  const SignupStep3Screen({super.key});
  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = signupState.allergies.toSet();
  }

  Future<bool> _imgExists() async {
    try {
      await rootBundle.load('assets/onboarding/allergies_food.png');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _finishSignup() async {
    signupState.allergies = _selected.toList();
    final ok = await authVM.signUp(
      email: signupState.email!,
      password: signupState.password!,
      displayName: signupState.name!,
      birthdate: signupState.birthdate,
      gender: signupState.gender,
      dietaryPrefs: signupState.dietaryPrefs,
      allergies: signupState.allergies,
    );
    if (!mounted) return;
    if (ok) {
      signupState.reset();
      // AuthGate reacts to auth state — no navigation needed
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (authVM.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: authVM,
        builder: (ctx) {
          final busy = authVM.busy;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnboardingHeader(),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: _imgExists(),
                  builder: (_, snap) {
                    if (snap.data == true) {
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/onboarding/allergies_food.png',
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pageHPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stepDots(2),
                      const SizedBox(height: 14),
                      Text('Food allergies',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                      const SizedBox(height: 4),
                      Text("We'll warn you about recipes containing these.",
                          style: TextStyle(
                              color: AppColors.textSec(context),
                              fontSize: 13)),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: AppCategories.commonAllergens.map((a) {
                          final on = _selected.contains(a);
                          return GestureDetector(
                            onTap: busy
                                ? null
                                : () => setState(() {
                                      if (on) {
                                        _selected.remove(a);
                                      } else {
                                        _selected.add(a);
                                      }
                                    }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: on
                                    ? AppColors.danger
                                    : AppColors.chipBg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(a,
                                  style: TextStyle(
                                    color: on
                                        ? Colors.white
                                        : AppColors.textPri(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: busy ? null : _finishSignup,
                        child: busy
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              )
                            : const Text('Get Started'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stepDots(int active) {
    return Row(
      children: List.generate(3, (i) {
        final selected = i == active;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: selected ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.divider(context),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
DART

ok "Signup screens written."

# =============================================================================
# 19. PANTRY ITEM SHEET (Add/Edit bottom sheet)
# =============================================================================
info "Writing pantry item sheet..."

cat > lib/view/screens/pantry_detail/pantry_item_sheet.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_units.dart';
import '../../../model/enums.dart';
import '../../../model/pantry_item.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/item_name_field.dart';

Future<PantryItem?> showPantryItemSheet(
  BuildContext context, {
  PantryItem? existing,
  String? initialName,
}) {
  return showModalBottomSheet<PantryItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PantryItemSheet(
      existing: existing,
      initialName: initialName,
    ),
  );
}

class _PantryItemSheet extends StatefulWidget {
  final PantryItem? existing;
  final String? initialName;
  const _PantryItemSheet({this.existing, this.initialName});
  @override
  State<_PantryItemSheet> createState() => _PantryItemSheetState();
}

class _PantryItemSheetState extends State<_PantryItemSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _imageUrlCtrl;
  late String _category;
  late String _unit;
  DateTime? _expiry;
  DateTime? _purchase;
  late StorageLocation _storage;
  late bool _favorite;
  String? _imageAsset;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? widget.initialName ?? '');
    _qtyCtrl = TextEditingController(
        text: e != null
            ? (e.quantity == e.quantity.truncate()
                ? e.quantity.toInt().toString()
                : e.quantity.toStringAsFixed(1))
            : '1');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _imageUrlCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _category = e?.category ?? AppCategories.all.first;
    _unit = e?.unitCode ?? 'unit';
    _expiry = e?.expiryDate;
    _purchase = e?.purchaseDate;
    _storage = e?.storage ?? StorageLocation.fridge;
    _favorite = e?.favorite ?? false;
    _imageAsset = e?.imageAsset;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial, {bool allowPast = true}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: allowPast ? DateTime(2020) : now,
      lastDate: DateTime(now.year + 5),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }
    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    // Duplicate check (only on ADD, not edit)
    if (!_isEdit) {
      final dup = pantryVM.findDuplicate(name);
      if (dup != null) {
        final choice = await showDialog<String>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Duplicate item'),
            content: Text(
                'You already have "${dup.name}" in your pantry. What would you like to do?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'add_qty'),
                child: const Text('Add to existing'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, 'add_new'),
                child: const Text('Add as new'),
              ),
            ],
          ),
        );
        if (choice == null || choice == 'cancel') return;
        if (choice == 'add_qty') {
          await pantryVM.bumpQuantity(dup, qty);
          if (!mounted) return;
          Navigator.pop(context, dup);
          return;
        }
        // else: fall through to add as new
      }
    }

    final item = PantryItem(
      id: _isEdit
          ? widget.existing!.id
          : 'p_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: _category,
      quantity: qty,
      unitCode: _unit,
      expiryDate: _expiry,
      addedDate: _isEdit ? widget.existing!.addedDate : DateTime.now(),
      purchaseDate: _purchase,
      imageAsset: _imageAsset,
      imageUrl: _imageUrlCtrl.text.trim().isEmpty
          ? null
          : _imageUrlCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      storage: _storage,
      favorite: _favorite,
      status:
          _isEdit ? widget.existing!.status : ItemStatus.active,
    );

    if (_isEdit) {
      await pantryVM.update(item);
    } else {
      await pantryVM.add(item);
    }
    if (!mounted) return;
    Navigator.pop(context, item);
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text('Delete ${widget.existing!.name}?'),
        content: const Text('This action can be undone from the snackbar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dc, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dc, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pop(context, null);
      await pantryVM.delete(widget.existing!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_isEdit ? 'Edit Item' : 'Add Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        )),
                  ),
                  if (_isEdit)
                    IconButton(
                      icon: Icon(
                        _favorite ? Icons.favorite : Icons.favorite_border,
                        color: _favorite
                            ? AppColors.danger
                            : AppColors.textSec(context),
                      ),
                      onPressed: () =>
                          setState(() => _favorite = !_favorite),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name (with autocomplete)
                    Text('Name',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    ItemNameField(
                      controller: _nameCtrl,
                      autofocus: !_isEdit,
                      onPicked: (known) {
                        setState(() {
                          _category = known.category;
                          _imageAsset = known.imageAsset;
                          _unit = known.defaultUnit;
                          if (known.imageUrl != null) {
                            _imageUrlCtrl.text = known.imageUrl!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    // Category
                    Text('Category',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: AppCategories.all
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 14),
                    // Quantity + Unit
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity',
                                  style: TextStyle(
                                      color: AppColors.textSec(context),
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _qtyCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  hintText: '1',
                                  prefixIcon:
                                      Icon(Icons.confirmation_number_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Unit',
                                  style: TextStyle(
                                      color: AppColors.textSec(context),
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _unit,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                items: AppUnits.all
                                    .map((u) => DropdownMenuItem(
                                        value: u.code,
                                        child: Text(u.label)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _unit = v ?? _unit),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Expiry
                    Text('Expiry date (optional)',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await _pickDate(_expiry,
                                  allowPast: false);
                              if (picked != null) {
                                setState(() => _expiry = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.event),
                              ),
                              child: Text(
                                _expiry == null
                                    ? 'Not set'
                                    : DateFormat('MMM d, yyyy')
                                        .format(_expiry!),
                                style: TextStyle(
                                  color: _expiry == null
                                      ? AppColors.textMut(context)
                                      : AppColors.textPri(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_expiry != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear expiry',
                            onPressed: () => setState(() => _expiry = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Purchase date
                    Text('Purchase date (optional)',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await _pickDate(_purchase);
                              if (picked != null) {
                                setState(() => _purchase = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.shopping_bag_outlined),
                              ),
                              child: Text(
                                _purchase == null
                                    ? 'Not set'
                                    : DateFormat('MMM d, yyyy')
                                        .format(_purchase!),
                                style: TextStyle(
                                  color: _purchase == null
                                      ? AppColors.textMut(context)
                                      : AppColors.textPri(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_purchase != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _purchase = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Storage
                    Text('Storage',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    SegmentedButton<StorageLocation>(
                      segments: const [
                        ButtonSegment(
                            value: StorageLocation.fridge,
                            icon: Icon(Icons.kitchen),
                            label: Text('Fridge')),
                        ButtonSegment(
                            value: StorageLocation.freezer,
                            icon: Icon(Icons.ac_unit),
                            label: Text('Freezer')),
                        ButtonSegment(
                            value: StorageLocation.pantry,
                            icon: Icon(Icons.shelves),
                            label: Text('Pantry')),
                      ],
                      selected: {_storage},
                      onSelectionChanged: (s) =>
                          setState(() => _storage = s.first),
                    ),
                    const SizedBox(height: 14),
                    // Image URL (optional — bug fix #9)
                    Text('Image URL (optional)',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _imageUrlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'https://... (paste an image link)',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Notes
                    Text('Notes (optional)',
                        style: TextStyle(
                            color: AppColors.textSec(context),
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Top shelf, vacuum sealed',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        if (_isEdit) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.danger),
                              label: const Text('Delete',
                                  style:
                                      TextStyle(color: AppColors.danger)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.danger, width: 1.5),
                              ),
                              onPressed: _delete,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            child: Text(_isEdit ? 'Save' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

ok "Pantry item sheet written."

# =============================================================================
# 20. MAIN SHELL + HOME + PANTRY + ADD ITEM SCREENS
# =============================================================================
info "Writing main shell + home + pantry + add item..."

# ---- main_shell -----------------------------------------------------------
cat > lib/view/screens/main/main_shell.dart <<'DART'
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/main_app_bar.dart';
import '../pantry_detail/pantry_screen.dart';
import '../recipes/recipe_screen.dart';
import '../misc/profile_screen.dart';
import 'add_item_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  static const _screens = <Widget>[
    HomeScreen(),
    PantryScreen(),
    AddItemScreen(),
    RecipeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final showAppBar = _index == 0 || _index == 1;
    return Scaffold(
      appBar: showAppBar ? const MainAppBar() : null,
      body: _screens[_index],
      bottomNavigationBar: ShelfBottomNav(currentIndex: _index),
    );
  }
}
DART

# ---- home_screen ----------------------------------------------------------
cat > lib/view/screens/main/home_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/home_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';
import '../recipes/matches_for_you_screen.dart';
import '../recipes/use_first_all_screen.dart';
import '../recipes/use_first_recipes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: Listenable.merge([homeVM, pantryVM]),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.pageHPad, 4, AppSizes.pageHPad, 24),
          children: [
            _welcomeCard(ctx),
            const SizedBox(height: 16),
            _statCards(ctx),
            const SizedBox(height: 20),
            _sectionHeader(ctx, 'Use First',
                onSeeAll: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => const UseFirstAllScreen()),
                    )),
            const SizedBox(height: 10),
            ...homeVM.useFirst.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: ValueKey('home_${item.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async => true,
                    onDismissed: (_) async {
                      final removed = item;
                      await pantryVM.delete(item.id);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('${removed.name} deleted'),
                            action: SnackBarAction(
                              label: AppStrings.undo,
                              onPressed: () async {
                                await pantryVM.add(removed);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: PantryItemCard(
                      item: item,
                      onTap: () =>
                          showPantryItemSheet(ctx, existing: item),
                    ),
                  ),
                )),
            if (homeVM.useFirst.isEmpty)
              _emptyBox(ctx, 'No items need using first', Icons.check_circle),
            const SizedBox(height: 20),
            _sectionHeader(ctx, 'Suggested Groceries'),
            const SizedBox(height: 10),
            _suggestedGroceriesCard(ctx),
            const SizedBox(height: 20),
            _sectionHeader(ctx, 'Recipes for expiring items',
                onSeeAll: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) =>
                              const UseFirstRecipesScreen()),
                    )),
            const SizedBox(height: 10),
            _recipeCard(ctx),
            const SizedBox(height: 20),
            _sectionHeader(ctx, 'Matches for you',
                onSeeAll: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => const MatchesForYouScreen()),
                    )),
            const SizedBox(height: 10),
            _matchesRow(ctx),
          ],
        );
      },
    );
  }

  Widget _welcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text('${homeVM.totalItems} items in your pantry',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _statCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _stat(context, Icons.inventory_2_outlined,
              '${homeVM.totalItems}', 'Total items', AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _stat(
              context,
              Icons.warning_amber_rounded,
              '${homeVM.expiringSoon}',
              'Expiring soon',
              AppColors.warning),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See all',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
      ],
    );
  }

  Widget _emptyBox(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.safe, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: AppColors.textSec(context))),
        ],
      ),
    );
  }

  Widget _suggestedGroceriesCard(BuildContext context) {
    final suggestions = homeVM.suggestions;
    if (suggestions.isEmpty) {
      return _emptyBox(
          context, 'All good — nothing suggested', Icons.check_circle);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: suggestions.map((s) {
          final expired = s['type'] == 'expired';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: expired
                        ? AppColors.dangerLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    expired ? Icons.error_outline : Icons.schedule,
                    color:
                        expired ? AppColors.danger : AppColors.warning,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPri(context),
                          )),
                      Text(s['reason']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: expired
                                ? AppColors.danger
                                : AppColors.warning,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _recipeCard(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.primaryDeeper,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Spinach & Berry\nSummer Salad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('15 mins • Easy',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.restaurant, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _matchesRow(BuildContext context) {
    final matches = [
      ('Zucchini &\nLeek Cream Soup', '30 mins'),
      ('Berry\nCompote Parfait', '10 mins'),
    ];
    return Row(
      children: matches.map((m) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.chipBg(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.restaurant_menu,
                        color: AppColors.textMut(context), size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(m.$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 4),
                Text(m.$2,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSec(context))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
DART

# ---- pantry_screen --------------------------------------------------------
cat > lib/view/screens/pantry_detail/pantry_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import 'pantry_item_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: pantryVM,
      builder: (ctx) {
        final items = pantryVM.filtered;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.pageHPad, 8, AppSizes.pageHPad, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: pantryVM.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search items…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: pantryVM.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            pantryVM.setQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageHPad),
                itemCount: AppCategories.filterChips.length,
                itemBuilder: (_, i) {
                  final label = AppCategories.filterChips[i];
                  final on = pantryVM.filter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => pantryVM.setFilter(label),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.primary
                              : AppColors.chipBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              color: on
                                  ? Colors.white
                                  : AppColors.textPri(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? _emptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.pageHPad, 4, AppSizes.pageHPad, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Dismissible(
                          key: ValueKey('pantry_${item.id}'),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: AppColors.safe,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          confirmDismiss: (_) async => true,
                          onDismissed: (dir) async {
                            if (dir == DismissDirection.startToEnd) {
                              // Right swipe: finish
                              final wasStatus = item.status;
                              await pantryVM.markFinished(item);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${item.name} marked finished'),
                                    action: SnackBarAction(
                                      label: AppStrings.undo,
                                      onPressed: () async {
                                        if (wasStatus.name == 'active') {
                                          await pantryVM.markActive(item);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                            } else {
                              final removed = item;
                              await pantryVM.delete(item.id);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('${removed.name} deleted'),
                                    action: SnackBarAction(
                                      label: AppStrings.undo,
                                      onPressed: () async {
                                        await pantryVM.add(removed);
                                      },
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: PantryItemCard(
                            item: item,
                            onFavoriteToggle: () =>
                                pantryVM.toggleFavorite(item),
                            onTap: () =>
                                showPantryItemSheet(ctx, existing: item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              color: AppColors.textMut(context), size: 64),
          const SizedBox(height: 12),
          Text('No items match your filter',
              style: TextStyle(color: AppColors.textSec(context))),
        ],
      ),
    );
  }
}
DART

# ---- add_item_screen (tab bar screen — opens sheet) ------------------------
cat > lib/view/screens/main/add_item_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showPantryItemSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppColors.textMut(context), size: 64),
            const SizedBox(height: 12),
            Text('Add a new item',
                style: TextStyle(
                    color: AppColors.textSec(context), fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Open form'),
              onPressed: () => showPantryItemSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
DART

ok "Main shell + home + pantry + add item written."

# =============================================================================
# 21. RECIPE SCREENS
# =============================================================================
info "Writing recipe screens..."

# ---- recipe_match_card (shared widget) -----------------------------------
cat > lib/view/widgets/recipe_match_card.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../constants/app_colors.dart';
import '../../model/recipe.dart';
import '../../viewmodel/recipe_vm.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import 'vm_listener.dart';

class RecipeMatchCard extends StatelessWidget {
  final Recipe recipe;
  final bool showUrgentBadge;
  const RecipeMatchCard({
    super.key,
    required this.recipe,
    this.showUrgentBadge = false,
  });

  Future<bool> _imageExists(String? path) async {
    if (path == null) return false;
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: recipeVM,
      builder: (ctx) {
        final fav = recipeVM.isFavorite(recipe.id);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: FutureBuilder<bool>(
                        future: _imageExists(recipe.imageAsset),
                        builder: (_, snap) {
                          if (snap.data == true) {
                            return Image.asset(
                              recipe.imageAsset!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            height: 120,
                            color: AppColors.chipBg(context),
                            child: Center(
                              child: Icon(Icons.restaurant_menu,
                                  color: AppColors.textMut(context),
                                  size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                    if (showUrgentBadge && recipe.urgent)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Use First',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          await recipeVM.toggleFavorite(recipe.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: fav
                                ? AppColors.danger
                                : AppColors.textSec(context),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: AppColors.textSec(context), size: 12),
                          const SizedBox(width: 4),
                          Text(recipe.time,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              )),
                          const SizedBox(width: 8),
                          Text('• ${recipe.difficulty}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec(context),
                              )),
                        ],
                      ),
                      if (!recipe.allFound && recipe.missingNote != null) ...[
                        const SizedBox(height: 4),
                        Text(recipe.missingNote!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
DART

# ---- recipe_screen --------------------------------------------------------
cat > lib/view/screens/recipes/recipe_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/recipe_match_card.dart';
import '../../widgets/vm_listener.dart';
import 'favorites_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: recipeVM,
      builder: (ctx) {
        final searching = recipeVM.isSearching;
        final list = searching ? recipeVM.searchResults : recipeVM.all;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.pageHPad, 12, AppSizes.pageHPad, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Recipes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                    ),
                    IconButton(
                      icon: Icon(
                          _showSearch ? Icons.close : Icons.search,
                          color: AppColors.textPri(context)),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchCtrl.clear();
                            recipeVM.clear();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite_border,
                          color: AppColors.textPri(context)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FavoritesScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.pageHPad, 0, AppSizes.pageHPad, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: recipeVM.setQuery,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, ingredient, or tag…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                color: AppColors.textMut(context), size: 56),
                            const SizedBox(height: 10),
                            Text('No recipes match',
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.pageHPad, 8, AppSizes.pageHPad, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => RecipeMatchCard(
                          recipe: list[i],
                          showUrgentBadge: true,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
DART

cat > lib/view/screens/recipes/recipe_detail_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../model/recipe.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/vm_listener.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  Future<bool> _imgExists() async {
    if (recipe.imageAsset == null) return false;
    try {
      await rootBundle.load(recipe.imageAsset!);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.bg(context),
            iconTheme: IconThemeData(
                color: isDark ? Colors.white : AppColors.primaryDark),
            actions: [
              VMListener(
                listenable: recipeVM,
                builder: (ctx) {
                  final fav = recipeVM.isFavorite(recipe.id);
                  return IconButton(
                    icon: Icon(
                      fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? AppColors.danger : Colors.white,
                    ),
                    onPressed: () => recipeVM.toggleFavorite(recipe.id),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<bool>(
                future: _imgExists(),
                builder: (_, snap) {
                  if (snap.data == true) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(recipe.imageAsset!, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Container(
                    color: AppColors.chipBg(context),
                    child: Center(
                      child: Icon(Icons.restaurant_menu,
                          color: AppColors.textMut(context), size: 80),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 16, AppSizes.pageHPad, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(recipe.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chipInfo(context, Icons.timer_outlined, recipe.time),
                    const SizedBox(width: 10),
                    _chipInfo(context, Icons.local_fire_department_outlined,
                        recipe.difficulty),
                    if (recipe.urgent) ...[
                      const SizedBox(width: 10),
                      _chipInfo(context, Icons.warning_amber_rounded,
                          'Use First',
                          color: AppColors.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (recipe.description.isNotEmpty)
                  Text(recipe.description,
                      style: TextStyle(
                        color: AppColors.textSec(context),
                        fontSize: 14,
                        height: 1.4,
                      )),
                const SizedBox(height: 20),
                if (recipe.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: recipe.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.chipBg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSec(context),
                                    fontWeight: FontWeight.w600,
                                  )),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: recipe.ingredients.map((ing) {
                      final missing = recipe.missingIngredients.contains(ing);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              missing
                                  ? Icons.remove_circle_outline
                                  : Icons.check_circle_outline,
                              color: missing
                                  ? AppColors.warning
                                  : AppColors.safe,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(ing,
                                  style: TextStyle(
                                    color: AppColors.textPri(context),
                                    fontSize: 14,
                                  )),
                            ),
                            if (missing)
                              TextButton.icon(
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 16),
                                label: const Text('Buy'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                ),
                                onPressed: () async {
                                  final newId =
                                      's_${DateTime.now().microsecondsSinceEpoch}';
                                  await shoppingVM.add(ShoppingItem(
                                    id: newId,
                                    name: ing,
                                    note: 'From recipe: ${recipe.title}',
                                  ));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '$ing added to shopping list'),
                                        action: SnackBarAction(
                                          label: AppStrings.undo,
                                          onPressed: () async {
                                            await shoppingVM.delete(newId);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipInfo(BuildContext context, IconData icon, String text,
      {Color? color}) {
    final c = color ?? AppColors.textSec(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                fontSize: 12,
                color: c,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
DART

# ---- use_first_all (pantry items with soonest expiry) --------------------
cat > lib/view/screens/recipes/use_first_all_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class UseFirstAllScreen extends StatelessWidget {
  const UseFirstAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: pantryVM,
        builder: (ctx) {
          final items = pantryVM.active
              .where((i) => i.hasExpiry)
              .toList()
            ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
            children: [
              Text('Use First',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('Items sorted by nearest expiry',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.safe, size: 56),
                        const SizedBox(height: 10),
                        Text('Nothing urgent',
                            style: TextStyle(
                                color: AppColors.textSec(context))),
                      ],
                    ),
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('uf_${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final removed = item;
                          await pantryVM.delete(item.id);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('${removed.name} deleted'),
                                action: SnackBarAction(
                                  label: AppStrings.undo,
                                  onPressed: () async =>
                                      await pantryVM.add(removed),
                                ),
                              ),
                            );
                          }
                        },
                        child: PantryItemCard(
                          item: item,
                          onTap: () =>
                              showPantryItemSheet(ctx, existing: item),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- use_first_recipes ----------------------------------------------------
cat > lib/view/screens/recipes/use_first_recipes_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/recipe_match_card.dart';
import '../../widgets/vm_listener.dart';

class UseFirstRecipesScreen extends StatelessWidget {
  const UseFirstRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          final items = recipeVM.useFirst;
          if (items.isEmpty) {
            return Center(
              child: Text('No urgent recipes',
                  style: TextStyle(color: AppColors.textSec(context))),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) =>
                RecipeMatchCard(recipe: items[i], showUrgentBadge: true),
          );
        },
      ),
    );
  }
}
DART

# ---- matches_for_you ------------------------------------------------------
cat > lib/view/screens/recipes/matches_for_you_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/recipe_match_card.dart';
import '../../widgets/vm_listener.dart';

class MatchesForYouScreen extends StatelessWidget {
  const MatchesForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          final items = recipeVM.all;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => RecipeMatchCard(recipe: items[i]),
          );
        },
      ),
    );
  }
}
DART

# ---- favorites_screen -----------------------------------------------------
cat > lib/view/screens/recipes/favorites_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/recipe_match_card.dart';
import '../../widgets/vm_listener.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          final items = recipeVM.favorites;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      color: AppColors.textMut(context), size: 64),
                  const SizedBox(height: 12),
                  Text('No favorites yet',
                      style:
                          TextStyle(color: AppColors.textSec(context))),
                  const SizedBox(height: 4),
                  Text('Tap the heart on any recipe to save it',
                      style: TextStyle(
                          color: AppColors.textMut(context), fontSize: 12)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => RecipeMatchCard(recipe: items[i]),
          );
        },
      ),
    );
  }
}
DART

ok "Recipe screens written."

# =============================================================================
# 22. SHOPPING + PROFILE + EDIT PROFILE + PRIVACY
# =============================================================================
info "Writing shopping + profile screens..."

# ---- shopping_list_screen (with UNDO on Move to Pantry) -------------------
cat > lib/view/screens/shopping/shopping_list_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _addQuick() async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    await shoppingVM.addIngredient(name, null);
    _addCtrl.clear();
  }

  Future<void> _moveCheckedToPantry() async {
    final beforePantryIds =
        pantryVM.all.map((i) => i.id).toSet();
    final moved = await shoppingVM.moveCheckedToPantry();
    final afterPantryIds =
        pantryVM.all.map((i) => i.id).toSet();
    final newPantryIds = afterPantryIds.difference(beforePantryIds).toList();

    if (!mounted) return;
    if (moved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No checked items to move')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${moved.length} item(s) moved to pantry'),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () async {
            await shoppingVM.restoreCheckedToShopping(moved, newPantryIds);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: shoppingVM,
        builder: (ctx) {
          final items = shoppingVM.all;
          final checkedCount = shoppingVM.checkedCount;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.pageHPad, 4, AppSizes.pageHPad, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Shopping List',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context),
                          )),
                    ),
                    Text('${items.length} items',
                        style: TextStyle(
                            color: AppColors.textSec(context))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageHPad),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        onSubmitted: (_) => _addQuick(),
                        decoration: const InputDecoration(
                          hintText: 'Add item…',
                          prefixIcon: Icon(Icons.add),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addQuick,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(64, 52),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('Your shopping list is empty',
                            style: TextStyle(
                                color: AppColors.textSec(context))),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.pageHPad, 4, AppSizes.pageHPad, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _row(context, items[i]),
                      ),
              ),
              if (checkedCount > 0)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.pageHPad, 8, AppSizes.pageHPad, 12),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label:
                          Text('Add $checkedCount checked to Pantry'),
                      onPressed: _moveCheckedToPantry,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, ShoppingItem item) {
    return Dismissible(
      key: ValueKey('shop_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final removed = item;
        await shoppingVM.delete(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${removed.name} removed'),
              action: SnackBarAction(
                label: AppStrings.undo,
                onPressed: () async {
                  await shoppingVM.add(removed);
                },
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              activeColor: AppColors.primary,
              onChanged: (_) => shoppingVM.toggleChecked(item),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context),
                        decoration: item.checked
                            ? TextDecoration.lineThrough
                            : null,
                      )),
                  if (item.note != null)
                    Text(item.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
DART

ok "Shopping list screen written."

# ---- profile_screen -------------------------------------------------------
cat > lib/view/screens/misc/profile_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../../viewmodel/home_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/profile_vm.dart';
import '../../widgets/vm_listener.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: Listenable.merge([authVM, profileVM, pantryVM, homeVM]),
      builder: (ctx) {
        final displayName = authVM.currentUser?.displayName ??
            authVM.profile?.displayName ??
            AppStrings.defaultName;
        final email = authVM.currentUser?.email ??
            authVM.profile?.email ??
            'guest@shelflife.app';
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        Text(email,
                            style: TextStyle(
                                color: AppColors.textSec(context),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: AppColors.textSec(context)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _analyticsSection(context),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Preferences', [
                _switchTile(
                  context,
                  Icons.dark_mode_outlined,
                  'Dark mode',
                  profileVM.darkMode,
                  (v) => profileVM.setDarkMode(v),
                ),
                _tile(context, Icons.lock_outline, 'Privacy', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyScreen()),
                  );
                }),
              ]),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Data', [
                _tile(context, Icons.refresh, 'Reset demo data', () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Reset all data?'),
                      content: const Text(
                          'This will restore the original 20 seed items and clear your current pantry, shopping list, and favorites.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dc, false),
                            child: const Text(AppStrings.cancel)),
                        TextButton(
                            onPressed: () => Navigator.pop(dc, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await profileVM.resetDemoData();
                    pantryVM.notifyListeners();
                    homeVM.notifyListeners();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo data reset')),
                      );
                    }
                  }
                }),
              ]),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Account', [
                _tile(context, Icons.logout, 'Log out', () async {
                  await authVM.signOut();
                  // AuthGate reacts
                }),
                _tile(context, Icons.delete_forever_outlined,
                    'Delete account', () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Delete your account?'),
                      content: const Text(
                          'This will permanently delete your account and all your data. This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dc, false),
                            child: const Text(AppStrings.cancel)),
                        TextButton(
                            onPressed: () => Navigator.pop(dc, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await authVM.deleteAccount();
                    if (!ok && authVM.error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authVM.error!)),
                      );
                    }
                  }
                }, danger: true),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsSection(BuildContext context) {
    // Real waste % (bug fix #5) and real category distribution (bug fix #4)
    final wasted = homeVM.wastedPercent;
    final trend = homeVM.wasteTrend;
    final categories = homeVM.categoryDistribution;

    // If no data, hide charts and show a message
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline,
                color: AppColors.textMut(context), size: 40),
            const SizedBox(height: 10),
            Text('Add some items to see analytics',
                style: TextStyle(color: AppColors.textSec(context))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              // Waste %
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wasted %',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                    Text('${wasted.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                    SizedBox(
                      height: 40,
                      child: LineChart(LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < trend.length; i++)
                                FlSpot(i.toDouble(), trend[i])
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              // Category donut
              Expanded(
                child: SizedBox(
                  height: 110,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                    sections: _pieSections(categories),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: categories.entries.map((e) {
              final color = _categoryColor(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: color),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, int> data) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];
    return data.entries.map((e) {
      final pct = e.value / total * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${pct.toStringAsFixed(0)}%',
        color: _categoryColor(e.key),
        radius: 32,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Dairy':     return const Color(0xFF60A5FA);
      case 'Produce':   return AppColors.primary;
      case 'Meat':      return const Color(0xFFEF4444);
      case 'Grains':    return const Color(0xFFF59E0B);
      case 'Beverages': return const Color(0xFF8B5CF6);
      case 'Snacks':    return const Color(0xFFEC4899);
      default:          return AppColors.neutral;
    }
  }

  Widget _settingsGroup(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSec(context),
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      VoidCallback onTap,
      {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: danger
                    ? AppColors.danger
                    : AppColors.textPri(context),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    color: danger
                        ? AppColors.danger
                        : AppColors.textPri(context),
                  )),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textMut(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(BuildContext context, IconData icon, String label,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPri(context),
                )),
          ),
          Switch(
            activeThumbColor: AppColors.primary,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
DART

ok "Profile screen written."

# ---- edit_profile (real password change via Firebase — bug fix #3) --------
cat > lib/view/screens/misc/edit_profile_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../model/user_profile.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: authVM.currentUser?.displayName ??
            authVM.profile?.displayName ??
            '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    // Update display name
    try {
      await Future.value();
      await authVM.currentUser?.updateDisplayName(name);
      await authVM.currentUser?.reload();
      final prof = authVM.profile ?? UserProfile(displayName: name);
      await authVM.saveProfile(prof.copyWith(displayName: name));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
      return;
    }

    // Update password if any (bug fix #3 — actually calls Firebase)
    if (_newPwCtrl.text.isNotEmpty || _confirmPwCtrl.text.isNotEmpty) {
      if (_newPwCtrl.text != _confirmPwCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
      if (_newPwCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Password must be at least 6 characters.')),
        );
        return;
      }
      final ok = await authVM.updatePassword(_newPwCtrl.text);
      if (!ok && authVM.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authVM.error!)),
          );
        }
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: VMListener(
        listenable: authVM,
        builder: (ctx) {
          final busy = authVM.busy;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
            children: [
              Text('Edit Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 20),
              Text('Display Name',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSec(context))),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                enabled: !busy,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Password (optional)',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSec(context))),
              const SizedBox(height: 6),
              TextField(
                controller: _newPwCtrl,
                obscureText: !_showNewPw,
                enabled: !busy,
                decoration: InputDecoration(
                  hintText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPw
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _showNewPw = !_showNewPw),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPwCtrl,
                obscureText: !_showConfirmPw,
                enabled: !busy,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPw
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _showConfirmPw = !_showConfirmPw),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: busy ? null : _saveAll,
                child: busy
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- privacy_screen (unchanged from v4) -----------------------------------
cat > lib/view/screens/misc/privacy_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../widgets/app_logo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _analytics = true;
  bool _personalized = true;
  bool _shareUsage = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.pageHPad, 12, AppSizes.pageHPad, 24),
        children: [
          Text('Privacy & Data',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 8),
          Text(
              'Control how ShelfLife uses your data to personalize your experience.',
              style: TextStyle(
                  color: AppColors.textSec(context), fontSize: 13)),
          const SizedBox(height: 20),
          _switchTile(context, 'Analytics', 'Help improve the app',
              _analytics, (v) => setState(() => _analytics = v)),
          const SizedBox(height: 10),
          _switchTile(
              context,
              'Personalized recommendations',
              'Use pantry data to suggest recipes',
              _personalized,
              (v) => setState(() => _personalized = v)),
          const SizedBox(height: 10),
          _switchTile(
              context,
              'Share anonymous usage',
              'Share aggregated data with researchers',
              _shareUsage,
              (v) => setState(() => _shareUsage = v)),
          const SizedBox(height: 30),
          Text('Your data',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 10),
          _actionTile(context, Icons.download_outlined, 'Export my data',
              () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Export feature coming soon')));
          }),
          _actionTile(context, Icons.delete_outline, 'Clear analytics data',
              () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics data cleared')));
          }),
        ],
      ),
    );
  }

  Widget _switchTile(BuildContext context, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec(context))),
              ],
            ),
          ),
          Switch(
              activeThumbColor: AppColors.primary,
              value: value,
              onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPri(context))),
              ),
              Icon(Icons.chevron_right,
                  color: AppColors.textMut(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
DART

ok "Edit profile + privacy screens written."

# =============================================================================
# 23. FINAL CLEANUP + SUMMARY
# =============================================================================
info "Running Flutter clean + pub get..."

flutter clean > /dev/null 2>&1 || warn "flutter clean failed (non-fatal)"
flutter pub get 2>&1 | tail -3 || warn "flutter pub get failed"

info "Running dart fix..."
dart fix --apply 2>&1 | tail -3 || warn "dart fix failed"

echo ""
echo "========================================================================"
echo -e "${GREEN}   ShelfLife v5.0 Ready${NC}"
echo "========================================================================"
echo ""
echo "New in v5.0:"
echo "  ✓ Firebase Authentication (Email/Password)"
echo "  ✓ Firestore cloud sync (per-user, offline-capable)"
echo "  ✓ Auth gate — auto-routes based on auth state"
echo "  ✓ Forgot Password flow with email reset link"
echo "  ✓ Real logout + delete account (wipes Firestore + Hive)"
echo "  ✓ Per-user Hive namespacing (pantry_{uid}, etc.)"
echo "  ✓ SyncService: Hive→Firestore on signup, Firestore→Hive on login"
echo "  ✓ Autocomplete on Add Item (Method 1: persistent catalog)"
echo "  ✓ Google/Facebook buttons stubbed (coming in v5.1)"
echo ""
echo "Bug fixes in v5.0:"
echo "  1. Reseeded items now use fixed reference dates (no more 'today')"
echo "  2. Missing recipe images → deferred to v5.1 (needs Cloudinary)"
echo "  3. Edit Profile password change actually calls Firebase"
echo "  4. Analytics donut chart uses real category counts"
echo "  5. 'Wasted %' derived from real (finished + expired) data"
echo "  6. Onboarding dietary prefs + allergies saved to Firestore profile"
echo "  7. Recipe Detail '+ Buy' now shows UNDO snackbar"
echo "  8. Expiry date is optional — shows 'Expiry not set' when null"
echo "  9. Optional image URL text field on Add Item"
echo " 10. UNDO on Home / Use First delete + Move-checked-to-Pantry"
echo ""
echo "Deferred to v5.1:"
echo "  • Google + Facebook Sign-In"
echo "  • Email verification"
echo "  • Account auto-linking"
echo "  • Cloudinary image URLs (Path A hardcoded)"
echo "  • Real image picker (Path B gallery upload)"
echo ""
echo "Next steps:"
echo "  1. flutter run"
echo "  2. Sign up with a new account, verify seed data uploads to Firestore"
echo "  3. Sign out → sign back in, verify data downloads correctly"
echo "  4. Test on 2 devices to see sync in action"
echo "  5. Tag v5.0 in git:"
echo "       git add . && git commit -m 'v5.0 Firebase + sync + autocomplete'"
echo "       git tag v5.0"
echo ""
echo "========================================================================"
