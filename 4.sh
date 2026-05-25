#!/usr/bin/env bash
# =============================================================================
# ShelfLife — Version 4 Update Script
# =============================================================================
# A full MVVM refactor + many new features. Run from the project root after
# v3 is in place.
#
#   cd /Users/anubhavsilwal/StudioProjects/demoui
#   chmod +x 4.sh
#   ./4.sh
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

if [ ! -f "pubspec.yaml" ] || [ ! -d "lib" ]; then
  err "Run this from your project root (the demoui/ folder)."
  exit 1
fi

if [ ! -f "lib/store/app_store.dart" ]; then
  err "v3 files not found. Run 3.sh first."
  exit 1
fi

info "Starting ShelfLife v4 (MVVM refactor) update..."

# =============================================================================
# 0. WIPE old lib/ structure cleanly — we're switching to MVVM
# =============================================================================
info "Removing v3 lib/ structure (keeping main.dart placeholder)..."

# Remove all v3 folders that are being replaced
rm -rf lib/theme lib/models lib/data lib/widgets lib/screens lib/store
# main.dart will be rewritten below

# =============================================================================
# 1. CREATE NEW MVVM FOLDER STRUCTURE
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

ok "MVVM folder structure created."

# =============================================================================
# 2. pubspec.yaml — bump version
# =============================================================================
info "Updating pubspec.yaml..."

PROJECT_NAME=$(grep -E "^name:" pubspec.yaml | head -1 | awk '{print $2}')
PROJECT_NAME=${PROJECT_NAME:-demoui}

cat > pubspec.yaml <<EOF
name: $PROJECT_NAME
description: "ShelfLife - Pantry management app."
publish_to: 'none'
version: 1.0.0+4

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
ok "pubspec.yaml updated."

# =============================================================================
# 3. CONSTANTS — colors, sizes, strings, categories, units
# =============================================================================
info "Writing constants..."

app_colors.dart

cat > lib/constants/app_units.dart <<'DART'
/// Unit handling — groups and conversion logic.
enum UnitGroup { mass, volume, count }

class AppUnit {
  final String code;     // 'g', 'kg', 'oz', 'lb', 'ml', 'l', 'tsp', etc.
  final String label;    // user-facing label
  final UnitGroup group;
  /// Factor to convert FROM this unit TO the base unit of its group.
  /// Mass base = gram. Volume base = milliliter. Count base = unit.
  final double toBase;

  const AppUnit(this.code, this.label, this.group, this.toBase);
}

class AppUnits {
  AppUnits._();

  // ---- Mass (base = gram) ------------------------------------------------
  static const g  = AppUnit('g',  'g',  UnitGroup.mass, 1.0);
  static const kg = AppUnit('kg', 'kg', UnitGroup.mass, 1000.0);
  static const oz = AppUnit('oz', 'oz', UnitGroup.mass, 28.3495);
  static const lb = AppUnit('lb', 'lb', UnitGroup.mass, 453.592);

  // ---- Volume (base = milliliter) ----------------------------------------
  static const ml    = AppUnit('ml',   'ml',  UnitGroup.volume, 1.0);
  static const l     = AppUnit('l',    'L',   UnitGroup.volume, 1000.0);
  static const tsp   = AppUnit('tsp',  'tsp', UnitGroup.volume, 4.92892);
  static const tbsp  = AppUnit('tbsp', 'tbsp',UnitGroup.volume, 14.7868);
  static const cup   = AppUnit('cup',  'cup', UnitGroup.volume, 236.588);
  static const flOz  = AppUnit('fl_oz','fl oz',UnitGroup.volume,29.5735);

  // ---- Count (base = unit) -----------------------------------------------
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

  /// Best secondary display unit (for "≈" hint).
  /// e.g. 500 g  → "≈ 1.10 lb"
  ///      1.5 lb → "≈ 680 g"
  static String? secondaryDisplay(double qty, AppUnit unit) {
    if (qty <= 0) return null;
    switch (unit.group) {
      case UnitGroup.mass:
        final inGrams = qty * unit.toBase;
        if (unit.code == 'g' || unit.code == 'kg') {
          // show lb
          final lbVal = inGrams / AppUnits.lb.toBase;
          return '≈ ${_fmt(lbVal)} lb';
        } else {
          // show g (or kg if big)
          if (inGrams >= 1000) return '≈ ${_fmt(inGrams / 1000)} kg';
          return '≈ ${_fmt(inGrams)} g';
        }
      case UnitGroup.volume:
        final inMl = qty * unit.toBase;
        if (unit.code == 'ml' || unit.code == 'l') {
          // show fl oz
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
# 4. MODELS — pure data classes
# =============================================================================
info "Writing models..."

cat > lib/model/enums.dart <<'DART'
/// All app-wide enums in one file.

enum ExpiryStatus { safe, soon, expired }

enum ItemStatus { active, finished }

extension ItemStatusX on ItemStatus {
  String get serialized => name;
  static ItemStatus parse(String? s) {
    return s == 'finished' ? ItemStatus.finished : ItemStatus.active;
  }
}

enum StorageLocation { fridge, freezer, pantry }

extension StorageLocationX on StorageLocation {
  String get label {
    switch (this) {
      case StorageLocation.fridge: return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.pantry: return 'Pantry';
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

cat > lib/model/pantry_item.dart <<'DART'
import 'enums.dart';

/// In-memory representation of a pantry item. Persisted to Hive as Map.
class PantryItem {
  final String id;
  final String name;
  final String category;
  final double quantity;       // numeric quantity
  final String unitCode;       // unit code (g, kg, oz, lb, ml, l, tsp, etc.)
  final DateTime expiryDate;
  final DateTime addedDate;
  final DateTime? purchaseDate;
  final String? imageAsset;
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
    required this.expiryDate,
    required this.addedDate,
    this.purchaseDate,
    this.imageAsset,
    this.imagePath,
    this.notes,
    this.storage = StorageLocation.fridge,
    this.favorite = false,
    this.status = ItemStatus.active,
  });

  // ---- Derived ------------------------------------------------------------
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  ExpiryStatus get expiryStatus {
    final d = daysUntilExpiry;
    if (d <= 1) return ExpiryStatus.expired;
    if (d <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.safe;
  }

  String get expiryLabel {
    final d = daysUntilExpiry;
    final months = const [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final dateStr = '${months[expiryDate.month - 1]} ${expiryDate.day}';
    if (d < 0) return 'Expired ($dateStr)';
    if (d == 0) return 'Expires Today';
    if (d == 1) return 'Expires tomorrow';
    if (d <= 7) return 'Expires in $d days ($dateStr)';
    return 'Exp: $dateStr';
  }

  String get quantityLabel {
    // Drop trailing .0 if integer
    if (quantity == quantity.truncate()) {
      return '${quantity.toInt()} $unitCode';
    }
    return '${quantity.toStringAsFixed(1)} $unitCode';
  }

  /// 0..1 — fraction of shelf life used (fuller = closer to expiry).
  double get progress {
    final total = expiryDate.difference(addedDate).inDays;
    if (total <= 0) return 1.0;
    final used = DateTime.now().difference(addedDate).inDays;
    final p = used / total;
    return p.clamp(0.0, 1.0);
  }

  bool get isFinished => status == ItemStatus.finished;
  bool get isActive => status == ItemStatus.active;

  // ---- Hive serialization -------------------------------------------------
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unitCode': unitCode,
        'expiry': expiryDate.toIso8601String(),
        'added': addedDate.toIso8601String(),
        'purchaseDate': purchaseDate?.toIso8601String(),
        'imageAsset': imageAsset,
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
        // older entries may have been stored as String — be tolerant
        quantity: _toDouble(m['quantity']),
        unitCode: (m['unitCode'] as String?) ?? 'unit',
        expiryDate: DateTime.parse(m['expiry'] as String),
        addedDate: DateTime.parse(m['added'] as String),
        purchaseDate: m['purchaseDate'] != null
            ? DateTime.parse(m['purchaseDate'] as String)
            : null,
        imageAsset: m['imageAsset'] as String?,
        imagePath: m['imagePath'] as String?,
        notes: m['notes'] as String?,
        storage: StorageLocationX.parse(m['storage'] as String?),
        favorite: (m['favorite'] as bool?) ?? false,
        status: ItemStatusX.parse(m['status'] as String?),
      );

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
    return 1.0;
  }

  PantryItem copyWith({
    String? name,
    String? category,
    double? quantity,
    String? unitCode,
    DateTime? expiryDate,
    DateTime? addedDate,
    DateTime? purchaseDate,
    String? imageAsset,
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
        expiryDate: expiryDate ?? this.expiryDate,
        addedDate: addedDate ?? this.addedDate,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        imageAsset: imageAsset ?? this.imageAsset,
        imagePath: imagePath ?? this.imagePath,
        notes: notes ?? this.notes,
        storage: storage ?? this.storage,
        favorite: favorite ?? this.favorite,
        status: status ?? this.status,
      );
}
DART

cat > lib/model/recipe.dart <<'DART'
class Recipe {
  final String id;
  final String title;
  final String time;        // human label, e.g. "20 mins"
  final int timeMinutes;    // numeric for filtering
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

ok "Models written."

# =============================================================================
# 5. SEED + RECIPE DATA (lives under lib/repo/ as static data sources)
# =============================================================================
info "Writing seed + recipe data..."

cat > lib/repo/seed_data.dart <<'DART'
/// First-launch seed data written into Hive once.
class SeedData {
  static DateTime _d(int days) =>
      DateTime.now().add(Duration(days: days));
  static DateTime _added(int daysAgo) =>
      DateTime.now().subtract(Duration(days: daysAgo));
  static String _id(int n) => 'p_$n';

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
            assetName: 'chicken_breast', storage: 'freezer',
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
        _entry(15, 'Tomatoes', 'Produce', 6, 'piece', 7, 1, storage: 'pantry'),
        _entry(16, 'Salmon Fillet', 'Meat', 2, 'piece', 2, 0,
            notes: 'Wild caught'),
        _entry(17, 'Olive Oil', 'Other', 500, 'ml', 180, 30,
            storage: 'pantry', notes: 'Extra virgin'),
        _entry(18, 'Brown Rice', 'Grains', 2, 'kg', 240, 15, storage: 'pantry'),
        _entry(19, 'Blueberries', 'Produce', 1, 'pack', 4, 1),
        _entry(20, 'Ground Beef', 'Meat', 500, 'g', 1, 2,
            notes: 'Use today or freeze'),
      ];

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
  }) {
    return {
      'id': _id(n),
      'name': name,
      'category': category,
      'quantity': quantity,
      'unitCode': unitCode,
      'expiry': _d(expInDays).toIso8601String(),
      'added': _added(addedAgo).toIso8601String(),
      'purchaseDate': _added(addedAgo).toIso8601String(),
      'imageAsset': assetName != null ? 'assets/items/$assetName.png' : null,
      'imagePath': null,
      'notes': notes,
      'storage': storage,
      'favorite': favorite,
      'status': 'active',
    };
  }

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
      description: 'A refreshing salad that uses your expiring spinach and strawberries.',
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
# 6. REPO INTERFACES + IMPLEMENTATIONS
# =============================================================================
info "Writing repository interfaces + implementations..."

# ---- pantry_repo + impl ----------------------------------------------------
cat > lib/repo/pantry_repo.dart <<'DART'
import '../model/pantry_item.dart';

/// Abstract contract for pantry persistence.
abstract class PantryRepo {
  Future<void> init();

  List<PantryItem> getAll();
  PantryItem? getById(String id);

  Future<void> add(PantryItem item);
  Future<void> update(PantryItem item);
  Future<void> delete(String id);

  Future<void> clear();
}
DART

cat > lib/repo/pantry_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../model/pantry_item.dart';
import 'pantry_repo.dart';
import 'seed_data.dart';

/// Hive-backed implementation of PantryRepo.
class PantryRepoImpl implements PantryRepo {
  static const _boxName = 'pantry';
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

  /// Seed-only helper used during first-launch only.
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
}
DART

cat > lib/repo/shopping_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import '../model/shopping_item.dart';
import 'shopping_repo.dart';
import 'seed_data.dart';

class ShoppingRepoImpl implements ShoppingRepo {
  static const _boxName = 'shopping';
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
  Future<void> clear();
}
DART

cat > lib/repo/favorites_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import 'favorites_repo.dart';
import 'seed_data.dart';

class FavoritesRepoImpl implements FavoritesRepo {
  static const _boxName = 'favorites';
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

# ---- settings_repo + impl --------------------------------------------------
cat > lib/repo/settings_repo.dart <<'DART'
abstract class SettingsRepo {
  Future<void> init();
  bool get darkMode;
  Future<void> setDarkMode(bool v);
  bool get seeded;
  Future<void> markSeeded();
  Future<void> clearSeeded();
}
DART

cat > lib/repo/settings_repo_impl.dart <<'DART'
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_repo.dart';

class SettingsRepoImpl implements SettingsRepo {
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
}
DART

# ---- recipe_repo + impl (no persistence — wraps static data) --------------
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

ok "Repos written (interfaces + implementations)."

# =============================================================================
# 7. SERVICE LOCATOR — singleton access to repos
# =============================================================================
info "Writing service locator..."

services.dart

ok "Service locator written."

# =============================================================================
# 8. THEME (view layer) — theme controller + light/dark themes
# =============================================================================
info "Writing theme files..."

theme_controller.dart

app_theme.dart

ok "Theme written."

# =============================================================================
# 9. MAIN.DART
# =============================================================================
info "Writing main.dart..."

cat > lib/main.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'view/theme/app_theme.dart';
import 'view/theme/theme_controller.dart';
import 'repo/services.dart';
import 'view/screens/misc/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Services.init();
  // Restore saved dark-mode preference
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
          home: const SplashScreen(),
        );
      },
    );
  }
}
DART

ok "main.dart written."

# =============================================================================
# 10. VIEWMODELS — pantry, shopping, recipe, home, profile, add_item
# =============================================================================
info "Writing viewmodels..."

# ---- pantry_vm -------------------------------------------------------------
cat > lib/viewmodel/pantry_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/enums.dart';
import '../repo/services.dart';

/// Encapsulates pantry list state, search, filter, and CRUD.
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

  // ---- Item lists ---------------------------------------------------------
  List<PantryItem> get all => Services.pantry.getAll();
  List<PantryItem> get active =>
      all.where((i) => i.status == ItemStatus.active).toList();
  List<PantryItem> get finished =>
      all.where((i) => i.status == ItemStatus.finished).toList();

  /// The list shown on the Pantry screen, after filter + search.
  List<PantryItem> get filtered {
    List<PantryItem> items;

    // Filter chip
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

    // Search
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.category.toLowerCase().contains(q) ||
              (i.notes ?? '').toLowerCase().contains(q))
          .toList();
    }

    // Sort by expiry
    items.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return items;
  }

  /// Items expiring soonest (active only). Used by Home "Use First".
  List<PantryItem> get useFirst {
    final list = active;
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  int get totalActiveCount => active.length;
  int get expiringSoonCount =>
      active.where((i) => i.daysUntilExpiry <= 2).length;

  // ---- CRUD ---------------------------------------------------------------
  Future<void> add(PantryItem item) async {
    await Services.pantry.add(item);
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

  /// Increase quantity on existing duplicate (used by add-item duplicate
  /// warning dialog).
  Future<void> bumpQuantity(PantryItem existing, double amount) async {
    final updated = existing.copyWith(quantity: existing.quantity + amount);
    await Services.pantry.update(updated);
    notifyListeners();
  }

  /// Find an existing active item with the same name (case-insensitive).
  PantryItem? findDuplicate(String name) {
    final n = name.trim().toLowerCase();
    for (final i in active) {
      if (i.name.trim().toLowerCase() == n) return i;
    }
    return null;
  }
}

/// Singleton — keep one instance app-wide.
final pantryVM = PantryVM();
DART

# ---- shopping_vm -----------------------------------------------------------
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

  /// Move all checked items to the pantry, then remove them from shopping.
  /// Returns number moved.
  Future<int> moveCheckedToPantry() async {
    final checked = all.where((i) => i.checked).toList();
    final now = DateTime.now();
    for (final s in checked) {
      final p = PantryItem(
        id: 'p_${now.microsecondsSinceEpoch}_${s.id}',
        name: s.name,
        category: 'Other',
        quantity: 1,
        unitCode: 'unit',
        expiryDate: now.add(const Duration(days: 7)),
        addedDate: now,
        purchaseDate: now,
      );
      await Services.pantry.add(p);
      await Services.shopping.delete(s.id);
    }
    pantryVM.notifyListeners();
    notifyListeners();
    return checked.length;
  }

  /// Add a single missing ingredient from a recipe to the shopping list.
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

# ---- recipe_vm -------------------------------------------------------------
cat > lib/viewmodel/recipe_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/recipe.dart';
import '../repo/services.dart';

class RecipeVM extends ChangeNotifier {
  String _query = '';
  int? _maxMinutes; // null = any

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

  // ---- Lists --------------------------------------------------------------
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

  /// Search results — name, ingredients, AND optional time filter.
  List<Recipe> get searchResults {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      // Time filter
      if (_maxMinutes != null && r.timeMinutes > _maxMinutes!) return false;
      // Text filter
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
import 'pantry_vm.dart';
import 'shopping_vm.dart';
import 'recipe_vm.dart';

class ProfileVM extends ChangeNotifier {
  bool get darkMode => Services.settings.darkMode;

  Future<void> setDarkMode(bool v) async {
    await Services.settings.setDarkMode(v);
    themeController.value = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Logout — soft sign-out. No data wipe.
  void logout() {
    // No-op besides UI nav. (Auth integration would clear session here.)
  }

  /// Delete account — wipes Hive boxes.
  Future<void> deleteAccount() async {
    await Services.pantry.clear();
    await Services.shopping.clear();
    await Services.favorites.clear();
    await Services.settings.clearSeeded();
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await Services.resetAndReseed();
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
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
  int get expiringSoon =>
      activeItems.where((i) => i.daysUntilExpiry <= 2).length;

  List<PantryItem> get useFirst {
    final list = activeItems;
    list.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    return list.take(5).toList();
  }

  /// "Suggested Groceries" derived from current pantry state.
  List<Map<String, String>> get suggestions {
    final result = <Map<String, String>>[];
    final expired = activeItems
        .where((i) => i.daysUntilExpiry <= 0)
        .take(2)
        .toList();
    final lowStock = activeItems
        .where((i) => i.daysUntilExpiry > 0 && i.daysUntilExpiry <= 3)
        .take(1)
        .toList();
    for (final i in expired) {
      result.add({'name': i.name, 'reason': 'Expired', 'type': 'expired'});
    }
    for (final i in lowStock) {
      result.add({
        'name': i.name,
        'reason': 'Expiring in ${i.daysUntilExpiry} day${i.daysUntilExpiry == 1 ? '' : 's'}',
        'type': 'low',
      });
    }
    return result;
  }
}

final homeVM = HomeVM();
DART

# ---- add_item_vm -----------------------------------------------------------
cat > lib/viewmodel/add_item_vm.dart <<'DART'
import 'package:flutter/foundation.dart';
import '../model/pantry_item.dart';
import '../model/enums.dart';
import 'pantry_vm.dart';

/// Holds form state for the Add Item screen.
class AddItemVM extends ChangeNotifier {
  String name = '';
  double quantity = 1;
  String unitCode = 'unit';
  String category = 'Other';
  DateTime? expiry;
  DateTime? purchaseDate;
  StorageLocation storage = StorageLocation.fridge;

  void update({
    String? name,
    double? quantity,
    String? unitCode,
    String? category,
    DateTime? expiry,
    DateTime? purchaseDate,
    StorageLocation? storage,
  }) {
    if (name != null) this.name = name;
    if (quantity != null) this.quantity = quantity;
    if (unitCode != null) this.unitCode = unitCode;
    if (category != null) this.category = category;
    if (expiry != null) this.expiry = expiry;
    if (purchaseDate != null) this.purchaseDate = purchaseDate;
    if (storage != null) this.storage = storage;
    notifyListeners();
  }

  void clearExpiry() {
    expiry = null;
    notifyListeners();
  }

  void clearPurchase() {
    purchaseDate = null;
    notifyListeners();
  }

  /// "Apply suggestion" — if purchaseDate is set, suggested expiry is 3 days
  /// after purchase. Otherwise 3 days from now.
  void applySuggestion(int days) {
    final base = purchaseDate ?? DateTime.now();
    expiry = base.add(Duration(days: days));
    notifyListeners();
  }

  PantryItem? findDuplicate() => pantryVM.findDuplicate(name);

  PantryItem buildItem() {
    final now = DateTime.now();
    return PantryItem(
      id: 'p_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      category: category,
      quantity: quantity,
      unitCode: unitCode,
      expiryDate: expiry ?? now.add(const Duration(days: 7)),
      addedDate: now,
      purchaseDate: purchaseDate ?? now,
      storage: storage,
    );
  }

  void reset() {
    name = '';
    quantity = 1;
    unitCode = 'unit';
    category = 'Other';
    expiry = null;
    purchaseDate = null;
    storage = StorageLocation.fridge;
    notifyListeners();
  }
}

final addItemVM = AddItemVM();
DART

ok "ViewModels written."

# =============================================================================
# 11. SHARED WIDGETS
# =============================================================================
info "Writing shared widgets..."

# ---- vm_listener helper ----------------------------------------------------
cat > lib/view/widgets/vm_listener.dart <<'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Convenience wrapper around ListenableBuilder for multiple VMs.
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

/// Multi-listenable convenience.
Listenable mergeListenables(List<Listenable> list) => Listenable.merge(list);
DART

# ---- app_logo --------------------------------------------------------------
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
        return Text(
          'ShelfLife',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: height * 0.75,
            fontWeight: FontWeight.w800,
          ),
        );
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
            width: size,
            height: size,
          );
        }
        return Container(
          width: size,
          height: size,
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

# ---- main_app_bar ----------------------------------------------------------
cat > lib/view/widgets/main_app_bar.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/misc/notifications_screen.dart';
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
          icon: Icon(Icons.notifications_none, color: AppColors.textPri(context)),
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

# ---- onboarding_header -----------------------------------------------------
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

# ---- bottom_nav ------------------------------------------------------------
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
              _navItem(context, 1, Icons.kitchen_outlined, Icons.kitchen, 'Pantry'),
              _addButton(context),
              _navItem(context, 3, Icons.receipt_long_outlined, Icons.receipt_long, 'Recipe'),
              _navItem(context, 4, Icons.person_outline, Icons.person, 'Profile'),
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
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconActive, color: Colors.white, size: 20),
                )
              else
                Icon(icon, color: AppColors.textPri(context), size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPri(context),
                ),
              ),
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
                width: 44,
                height: 44,
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
              Text(
                'Add',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPri(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

# ---- pantry_item_card ------------------------------------------------------
cat > lib/view/widgets/pantry_item_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../model/pantry_item.dart';
import '../../model/enums.dart';

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
      case ExpiryStatus.expired: return AppColors.danger;
      case ExpiryStatus.soon:    return AppColors.warning;
      case ExpiryStatus.safe:    return AppColors.safe;
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
                  child:
                      Icon(Icons.more_vert, color: AppColors.textSec(context)),
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
        width: 60,
        height: 60,
        color: AppColors.chipBg(context),
        child: item.imageAsset != null
            ? Image.asset(
                item.imageAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('img',
                      style: TextStyle(
                          color: AppColors.textMut(context), fontSize: 12)),
                ),
              )
            : Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textMut(context), size: 24),
              ),
      ),
    );
  }

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
                  decoration: item.isFinished
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (compact)
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
            style:
                TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
        const SizedBox(height: 4),
        if (!compact)
          Row(
            children: [
              Icon(
                item.isFinished
                    ? Icons.check_circle
                    : item.expiryStatus == ExpiryStatus.expired
                        ? Icons.error_outline
                        : item.expiryStatus == ExpiryStatus.soon
                            ? Icons.calendar_today
                            : Icons.check_circle_outline,
                color: _statusColor,
                size: 14,
              ),
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
            style:
                TextStyle(fontSize: 12, color: AppColors.textSec(context)),
          ),
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
    );
  }

  String _daysLabel() {
    if (item.isFinished) return 'Done';
    final d = item.daysUntilExpiry;
    if (d < 0) return 'Expired';
    if (d == 0) return 'Today';
    if (d == 1) return '1 Day';
    return '$d Days';
  }
}
DART

ok "Shared widgets written."

# =============================================================================
# 12. SPLASH + LOGIN + ONBOARDING SCREENS
# =============================================================================
info "Writing splash + login + onboarding..."

# ---- splash ----------------------------------------------------------------
splash_screen.dart

# ---- notifications ---------------------------------------------------------
cat > lib/view/screens/misc/notifications_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = [
    {
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.danger,
      'title': 'Whole Milk expires today',
      'subtitle': 'Use it for the Spaghetti Carbonara recipe.',
      'time': '2h ago',
    },
    {
      'icon': Icons.calendar_today,
      'color': AppColors.warning,
      'title': 'Baby Spinach expires in 2 days',
      'subtitle': 'Try our Spinach & Berry Summer Salad.',
      'time': '8h ago',
    },
    {
      'icon': Icons.shopping_cart,
      'color': AppColors.primary,
      'title': 'Milk added to shopping list',
      'subtitle': 'Low stock alert was triggered.',
      'time': 'Yesterday',
    },
  ];

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
        padding: const EdgeInsets.all(20),
        children: [
          Text('Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 16),
          ..._items.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: (n['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n['icon'] as IconData,
                          color: n['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPri(context),
                              )),
                          const SizedBox(height: 2),
                          Text(n['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSec(context),
                              )),
                          const SizedBox(height: 4),
                          Text(n['time'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMut(context),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
DART

# ---- login -----------------------------------------------------------------
cat > lib/view/screens/auth/login_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../onboarding/signup_step1_screen.dart';
import '../main/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.asset(
                  'assets/onboarding/login_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFDDE5D4),
                    child: const Center(
                      child: Icon(Icons.kitchen,
                          size: 64, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AppLogoIcon(size: 72),
              const SizedBox(height: 16),
              const AppLogoText(height: 38),
              const SizedBox(height: 8),
              Text(
                'Freshness at your fingertips',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textPri(context)),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _login,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.divider(context)),
                        foregroundColor: AppColors.textPri(context),
                      ),
                      icon: const Icon(Icons.g_mobiledata,
                          color: Colors.red, size: 32),
                      label: const Text('Sign in with Google'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.facebookBlue,
                      ),
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text('Sign in with Facebook'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR EMAIL',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSec(context),
                                letterSpacing: 1,
                              )),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email or Username',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPri(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPri(context),
                            )),
                        const Text('Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep1Screen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: AppColors.textPri(context), fontSize: 14),
                          children: const [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Register',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
DART

# ---- signup_step1 (working password reveal + date picker) ------------------

signup_step1_screen.dart

signup_step2_screen.dart

signup_step3_screen.dart

ok "Splash + login + onboarding written."

# =============================================================================
# 13. PANTRY EDIT BOTTOM SHEET (unit conversion + storage location + notes)
# =============================================================================
info "Writing pantry edit bottom sheet..."

cat > lib/view/screens/pantry_detail/pantry_item_sheet.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_units.dart';
import '../../../model/pantry_item.dart';
import '../../../model/enums.dart';
import '../../../viewmodel/pantry_vm.dart';

/// Modal bottom sheet for ADD or EDIT pantry item.
/// Pass [existing] to edit; omit it to add.
Future<void> showPantryItemSheet(BuildContext context,
    {PantryItem? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PantryItemForm(existing: existing),
  );
}

class _PantryItemForm extends StatefulWidget {
  final PantryItem? existing;
  const _PantryItemForm({this.existing});
  @override
  State<_PantryItemForm> createState() => _PantryItemFormState();
}

class _PantryItemFormState extends State<_PantryItemForm> {
  late final TextEditingController _name;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _notes;
  late final TextEditingController _imagePath;
  late String _category;
  late String _unitCode;
  late DateTime _expiry;
  DateTime? _purchase;
  late StorageLocation _storage;
  late bool _favorite;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _qtyCtrl = TextEditingController(
        text: e != null ? _trimZeros(e.quantity) : '1');
    _notes = TextEditingController(text: e?.notes ?? '');
    _imagePath = TextEditingController(text: e?.imagePath ?? '');
    _category = e?.category ?? 'Other';
    if (!AppCategories.all.contains(_category)) _category = 'Other';
    _unitCode = e?.unitCode ?? 'unit';
    _expiry = e?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    _purchase = e?.purchaseDate;
    _storage = e?.storage ?? StorageLocation.fridge;
    _favorite = e?.favorite ?? false;
  }

  static String _trimZeros(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _qtyCtrl.dispose();
    _notes.dispose();
    _imagePath.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select expiry date',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _pickPurchase() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchase ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      helpText: 'Select purchase date',
    );
    if (picked != null) setState(() => _purchase = picked);
  }

  double _qtyAsDouble() {
    return double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }
    final now = DateTime.now();
    final item = PantryItem(
      id: widget.existing?.id ?? 'p_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      quantity: _qtyAsDouble(),
      unitCode: _unitCode,
      expiryDate: _expiry,
      addedDate: widget.existing?.addedDate ?? now,
      purchaseDate: _purchase,
      imageAsset: widget.existing?.imageAsset,
      imagePath:
          _imagePath.text.trim().isEmpty ? null : _imagePath.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      storage: _storage,
      favorite: _favorite,
      status: widget.existing?.status ?? ItemStatus.active,
    );

    if (_isEdit) {
      pantryVM.update(item);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated.')),
      );
      return;
    }

    // For NEW items — duplicate check
    final dup = pantryVM.findDuplicate(item.name);
    if (dup != null) {
      _showDuplicateDialog(item, dup);
      return;
    }

    pantryVM.add(item);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added.')),
    );
  }

  void _showDuplicateDialog(PantryItem newItem, PantryItem existing) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Already in pantry'),
        content: Text(
            'You already have "${existing.name}" (${existing.quantityLabel}) in your pantry. What do you want to do?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pantryVM.bumpQuantity(existing, _qtyAsDouble());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Increased ${existing.name} by ${_qtyAsDouble()} ${existing.unitCode}.')));
            },
            child: const Text('Increase existing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () {
              Navigator.pop(context);
              pantryVM.add(newItem);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item added (duplicate).')),
              );
            },
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final secondary =
        AppUnits.secondaryDisplay(_qtyAsDouble(), AppUnits.byCode(_unitCode));
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_isEdit ? 'Edit Item' : 'Add New Item',
                      style: TextStyle(
                        fontSize: 22,
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
                          : AppColors.textMut(context),
                    ),
                    onPressed: () =>
                        setState(() => _favorite = !_favorite),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(context, 'Item name'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Fresh Chicken Breast',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
            ),
            const SizedBox(height: 14),
            // Quantity + Unit + Category
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Quantity'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 500',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Unit'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _unitCode,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: AppUnits.all
                            .map((u) => DropdownMenuItem(
                                  value: u.code,
                                  child: Text(u.label),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _unitCode = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (secondary != null) ...[
              const SizedBox(height: 4),
              Text(secondary,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSec(context))),
            ],
            const SizedBox(height: 14),
            _label(context, 'Category'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: AppCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _label(context, 'Expiry Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickExpiry,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                child: Text(
                  '${_expiry.year}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: AppColors.textPri(context)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Purchase Date (optional)'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickPurchase,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  isDense: true,
                  suffixIcon: _purchase != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _purchase = null),
                        )
                      : null,
                ),
                child: Text(
                  _purchase == null
                      ? 'Not set'
                      : '${_purchase!.year}-${_purchase!.month.toString().padLeft(2, '0')}-${_purchase!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: _purchase == null
                        ? AppColors.textMut(context)
                        : AppColors.textPri(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Storage Location'),
            const SizedBox(height: 6),
            SegmentedButton<StorageLocation>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: StorageLocation.fridge,
                    label: Text('Fridge'),
                    icon: Icon(Icons.kitchen, size: 18)),
                ButtonSegment(
                    value: StorageLocation.freezer,
                    label: Text('Freezer'),
                    icon: Icon(Icons.ac_unit, size: 18)),
                ButtonSegment(
                    value: StorageLocation.pantry,
                    label: Text('Pantry'),
                    icon: Icon(Icons.inventory_2, size: 18)),
              ],
              selected: {_storage},
              onSelectionChanged: (s) => setState(() => _storage = s.first),
            ),
            const SizedBox(height: 14),
            _label(context, 'Image path (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _imagePath,
              decoration: const InputDecoration(
                hintText: 'assets/items/example.png',
                prefixIcon: Icon(Icons.image_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Top shelf, vacuum sealed...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEdit)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        pantryVM.delete(widget.existing!.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted.')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      label: const Text('Delete',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                if (_isEdit) const SizedBox(width: 12),
                Expanded(
                  flex: _isEdit ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    child: Text(_isEdit ? 'Save Changes' : 'Add to Pantry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext c, String s) => Text(s,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSec(c),
      ));
}
DART
ok "Pantry sheet written."

# =============================================================================
# 14. MAIN SHELL
# =============================================================================
info "Writing main_shell..."

cat > lib/view/screens/main/main_shell.dart <<'DART'
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'add_item_screen.dart';
import 'recipe_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatelessWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const PantryScreen(),
      const AddItemScreen(),
      const RecipeScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[initialIndex],
      bottomNavigationBar: ShelfBottomNav(currentIndex: initialIndex),
    );
  }
}
DART
ok "Main shell written."

# =============================================================================
# 15. HOME SCREEN
# =============================================================================
info "Writing home_screen..."

home_screen.dart

ok "Home screen written."

# =============================================================================
# 16. PANTRY SCREEN — swipe both ways, finished filter, favorites filter
# =============================================================================
info "Writing pantry_screen..."

cat > lib/view/screens/main/pantry_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../model/pantry_item.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/pantry_item_card.dart';
import '../../widgets/vm_listener.dart';
import '../pantry_detail/pantry_item_sheet.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = pantryVM.query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Left swipe = delete with undo
  Future<void> _onDelete(PantryItem item) async {
    await pantryVM.delete(item.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} deleted.'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => pantryVM.add(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Right swipe = mark finished + offer to add to shopping list
  Future<bool> _onMarkFinished(PantryItem item) async {
    final addToList = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as finished?'),
        content: Text(
            '${item.name} will be moved to the "Finished" category. Add it to your shopping list too?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, just finish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, add to list'),
          ),
        ],
      ),
    );

    if (addToList == null) return false; // user cancelled

    await pantryVM.markFinished(item);
    if (addToList) {
      await shoppingVM.add(ShoppingItem(
        id: 's_${DateTime.now().microsecondsSinceEpoch}',
        name: item.name,
        note: 'Finished — restock',
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addToList
              ? '${item.name} finished + added to shopping list.'
              : '${item.name} marked as finished.'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () => pantryVM.markActive(item),
          ),
        ),
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: pantryVM,
        builder: (ctx) {
          final items = pantryVM.filtered;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: pantryVM.setQuery,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search your pantry...',
                  filled: true,
                  fillColor: AppColors.card(context),
                  suffixIcon: pantryVM.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            pantryVM.setQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppCategories.filterChips.map((f) {
                    final selected = f == pantryVM.filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => pantryVM.setFilter(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.chipUnsel(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (f == 'Favorites') ...[
                                Icon(Icons.favorite,
                                    size: 14,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.danger),
                                const SizedBox(width: 4),
                              ],
                              if (f == 'Finished') ...[
                                Icon(Icons.check_circle,
                                    size: 14,
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 4),
                              ],
                              Text(f,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPri(context),
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                _emptyState(context)
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _swipeWrap(item),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _swipeWrap(PantryItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      // Right swipe (startToEnd) = finish, Left swipe (endToStart) = delete
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.safe,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Finish',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete
          final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete this item?'),
                  content: Text('Remove "${item.name}" from your pantry?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (ok) await _onDelete(item);
          return ok;
        } else {
          // Mark finished
          return await _onMarkFinished(item);
        }
      },
      child: PantryItemCard(
        item: item,
        showMenu: true,
        onTap: () => showPantryItemSheet(context, existing: item),
        onFavoriteToggle: () => pantryVM.toggleFavorite(item),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text(
            pantryVM.query.isNotEmpty || pantryVM.filter != 'All'
                ? 'No matches found.'
                : 'Your pantry is empty.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSec(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pantryVM.query.isNotEmpty || pantryVM.filter != 'All'
                ? 'Try a different search or filter.'
                : 'Tap + to add your first item.',
            style:
                TextStyle(fontSize: 13, color: AppColors.textMut(context)),
          ),
        ],
      ),
    );
  }
}
DART
ok "Pantry screen written."

# =============================================================================
# 17. ADD ITEM SCREEN — duplicate check, purchase date, units
# =============================================================================
info "Writing add_item_screen..."

add_item_screen.dart

ok "Add item screen written."

# =============================================================================
# 18. RECIPE SCREEN — with collapsible search
# =============================================================================
info "Writing recipe_screen..."

cat > lib/view/screens/main/recipe_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/vm_listener.dart';
import '../recipes/recipe_detail_screen.dart';
import '../recipes/use_first_recipes_screen.dart';
import '../recipes/matches_for_you_screen.dart';
import '../recipes/favorites_screen.dart';
import '../recipes/recipe_match_card.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final _searchCtrl = TextEditingController();
  final List<String> _selectedIngredients = ['Chicken Breast', 'Bell Peppers'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: recipeVM,
        builder: (ctx) {
          return Column(
            children: [
              _searchBar(context),
              if (recipeVM.maxMinutes != null) _activeFilterBar(context),
              Expanded(
                child: recipeVM.isSearching
                    ? _searchResults(context)
                    : _defaultRecipeView(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: recipeVM.setQuery,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search recipes by name or ingredient',
          filled: true,
          fillColor: AppColors.card(context),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recipeVM.query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchCtrl.clear();
                    recipeVM.setQuery('');
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.timer_outlined,
                  color: recipeVM.maxMinutes != null
                      ? AppColors.primaryDark
                      : AppColors.textMut(context),
                ),
                onPressed: () => _showTimeFilter(context),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showTimeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          int? current = recipeVM.maxMinutes;
          final options = [null, 5, 15, 30, 60];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Max cooking time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((o) {
                    final selected = current == o;
                    final label = o == null ? 'Any' : '≤ $o min';
                    return GestureDetector(
                      onTap: () {
                        recipeVM.setMaxMinutes(o);
                        Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.chipUnsel(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPri(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _activeFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Chip(
            label: Text('≤ ${recipeVM.maxMinutes} min'),
            backgroundColor: AppColors.primaryLight,
            labelStyle: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            deleteIcon: const Icon(Icons.close,
                size: 16, color: AppColors.primaryDark),
            onDeleted: () => recipeVM.setMaxMinutes(null),
          ),
        ],
      ),
    );
  }

  Widget _searchResults(BuildContext context) {
    final results = recipeVM.searchResults;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          children: [
            Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                recipeVM.clear();
              },
              child: const Text('Clear all',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: AppColors.textMut(context)),
                  const SizedBox(height: 12),
                  Text('No recipes match.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSec(context))),
                ],
              ),
            ),
          )
        else
          ...results.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RecipeMatchCard(recipe: r),
              )),
      ],
    );
  }

  Widget _defaultRecipeView(BuildContext context) {
    final useFirst = recipeVM.useFirst;
    final smallSet =
        recipeVM.all.where((r) => !r.urgent).take(2).toList();
    final favorites = recipeVM.favorites;
    final matches = recipeVM.matches;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Use First Suggestions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UseFirstRecipesScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (useFirst.isNotEmpty) _featuredCard(useFirst.first),
        const SizedBox(height: 12),
        if (smallSet.length >= 2)
          Row(
            children: [
              Expanded(child: _smallRecipe(smallSet[0])),
              const SizedBox(width: 12),
              Expanded(child: _smallRecipe(smallSet[1])),
            ],
          ),
        const SizedBox(height: 24),
        Text('Find by Ingredients',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedIngredients.map((i) => Chip(
                  label: Text(i,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      )),
                  backgroundColor: AppColors.primaryLight,
                  deleteIcon: const Icon(Icons.close,
                      size: 16, color: AppColors.primaryDark),
                  onDeleted: () =>
                      setState(() => _selectedIngredients.remove(i)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                )),
            ActionChip(
              label: Icon(Icons.add,
                  size: 18, color: AppColors.textPri(context)),
              backgroundColor: AppColors.card(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.divider(context)),
              ),
              onPressed: _addIngredientDialog,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Favorites section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.danger, size: 22),
                const SizedBox(width: 6),
                Text('Favorite Recipes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (favorites.isEmpty)
          _emptyFavorites(context)
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _favoriteCard(favorites[i]),
            ),
          ),
        const SizedBox(height: 24),
        // Matches
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Matches for you',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPri(context),
                )),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MatchesForYouScreen()),
              ),
              child: const Text('View All',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...matches.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecipeMatchCard(recipe: r),
            )),
      ],
    );
  }

  void _addIngredientDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Onion'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty &&
                  !_selectedIngredients.contains(name)) {
                setState(() => _selectedIngredients.add(name));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: r.imageAsset != null
                ? Image.asset(
                    r.imageAsset!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _featuredFallback(),
                  )
                : _featuredFallback(),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14, bottom: 14, right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('HIGH URGENCY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                ),
                const SizedBox(height: 8),
                Text(r.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(r.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _featuredFallback() {
    return Container(
      height: 200,
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _smallRecipe(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Container(
        height: 130,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned.fill(
              child: r.imageAsset != null
                  ? Image.asset(
                      r.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _smallFallback(),
                    )
                  : _smallFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10, bottom: 10, right: 10,
              child: Text(r.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Container _smallFallback() {
    return Container(
      color: const Color(0xFF6B7280),
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white),
      ),
    );
  }

  Widget _favoriteCard(Recipe r) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: SizedBox(
        width: 180,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: r.imageAsset != null
                    ? Image.asset(r.imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppColors.chipBg(context),
                              child: Icon(Icons.restaurant,
                                  color: AppColors.textMut(context),
                                  size: 32),
                            ))
                    : Container(
                        color: AppColors.chipBg(context),
                        child: Icon(Icons.restaurant,
                            color: AppColors.textMut(context), size: 32),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPri(context),
                        )),
                    const SizedBox(height: 4),
                    Text('${r.time} • ${r.difficulty}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyFavorites(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite_border,
              color: AppColors.textMut(context), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No favorites yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text('Tap the heart on a recipe to save it here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART
ok "Recipe screen written."

# =============================================================================
# 19. RECIPE MATCH CARD — extracted into its own file for reuse
# =============================================================================
info "Writing recipe match card..."

cat > lib/view/screens/recipes/recipe_match_card.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import 'recipe_detail_screen.dart';

class RecipeMatchCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeMatchCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final accent = r.allFound ? AppColors.safe : AppColors.warning;
    final isFav = recipeVM.isFavorite(r.id);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: r)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: accent, width: 5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: r.imageAsset != null
                  ? Image.asset(
                      r.imageAsset!,
                      width: 70, height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70, height: 70,
                        color: AppColors.chipBg(context),
                        child: Icon(Icons.restaurant,
                            color: AppColors.textMut(context)),
                      ),
                    )
                  : Container(
                      width: 70, height: 70,
                      color: AppColors.chipBg(context),
                      child: Icon(Icons.restaurant,
                          color: AppColors.textMut(context)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPri(context),
                      )),
                  const SizedBox(height: 4),
                  Text('${r.time} • ${r.difficulty}',
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 13)),
                  const SizedBox(height: 6),
                  if (r.allFound)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safeLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ALL INGREDIENTS FOUND',
                          style: TextStyle(
                            color: AppColors.safe,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          )),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                              '${r.missingIngredients.length} MISSING',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.missingNote ?? '',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: AppColors.textSec(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.danger : AppColors.warning,
              ),
              onPressed: () => recipeVM.toggleFavorite(r.id),
            ),
          ],
        ),
      ),
    );
  }
}
DART
ok "Recipe match card written."

# =============================================================================
# 20. RECIPE SUB-SCREENS — use-first, matches, favorites, detail
# =============================================================================
info "Writing recipe sub-screens..."

# ---- Recipe Detail Screen (with working "+ Buy") ---------------------------
cat > lib/view/screens/recipes/recipe_detail_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/recipe.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/vm_listener.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: VMListener(
        listenable: Listenable.merge([pantryVM, shoppingVM, recipeVM]),
        builder: (ctx) {
          final isFav = recipeVM.isFavorite(recipe.id);
          final pantryNames =
              pantryVM.active.map((p) => p.name.toLowerCase()).toSet();
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primaryDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.danger : Colors.white,
                    ),
                    onPressed: () => recipeVM.toggleFavorite(recipe.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageAsset != null
                      ? Image.asset(
                          recipe.imageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF6B7280)),
                        )
                      : const ColoredBox(color: Color(0xFF6B7280)),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.time,
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                            const SizedBox(width: 12),
                            Icon(Icons.local_fire_department_outlined,
                                size: 16,
                                color: AppColors.textSec(context)),
                            const SizedBox(width: 4),
                            Text(recipe.difficulty,
                                style: TextStyle(
                                    color: AppColors.textSec(context))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recipe.description.isNotEmpty)
                          Text(recipe.description,
                              style: TextStyle(
                                color: AppColors.textPri(context),
                                fontSize: 14,
                                height: 1.45,
                              )),
                        const SizedBox(height: 16),
                        if (recipe.tags.isNotEmpty)
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: recipe.tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(t,
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          )),
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 24),
                        Text('Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map((ing) {
                          final have = pantryNames.any(
                              (p) => p.contains(ing.toLowerCase()));
                          final inList = shoppingVM.all.any((s) =>
                              s.name.toLowerCase() == ing.toLowerCase());
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  have
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color: have
                                      ? AppColors.safe
                                      : AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(ing,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPri(context),
                                      )),
                                ),
                                if (!have)
                                  TextButton.icon(
                                    onPressed: inList
                                        ? null
                                        : () {
                                            shoppingVM.addIngredient(
                                                ing,
                                                'For ${recipe.title}');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  '$ing added to shopping list.'),
                                            ));
                                          },
                                    icon: Icon(
                                      inList
                                          ? Icons.check
                                          : Icons.add_shopping_cart,
                                      size: 16,
                                      color: inList
                                          ? AppColors.safe
                                          : AppColors.primaryDark,
                                    ),
                                    label: Text(
                                      inList ? 'In list' : 'Buy',
                                      style: TextStyle(
                                        color: inList
                                            ? AppColors.safe
                                            : AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- Use First All (pantry items) -----------------------------------------
cat > lib/view/screens/recipes/use_first_all_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
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
            ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Use First',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('${items.length} items sorted by soonest expiry.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Pantry is empty.',
                        style:
                            TextStyle(color: AppColors.textSec(context))),
                  ),
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PantryItemCard(
                        item: item,
                        compact: true,
                        onTap: () =>
                            showPantryItemSheet(context, existing: item),
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

# ---- Use First Recipes ----------------------------------------------------
cat > lib/view/screens/recipes/use_first_recipes_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import 'recipe_match_card.dart';

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
          final recipes = recipeVM.useFirst.isEmpty
              ? recipeVM.all.take(5).toList()
              : recipeVM.useFirst;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Use First Suggestions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text(
                  'Recipes that use your expiring items so nothing goes to waste.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              ...recipes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecipeMatchCard(recipe: r),
                  )),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- Matches for you -------------------------------------------------------
cat > lib/view/screens/recipes/matches_for_you_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import 'recipe_match_card.dart';

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
          final recipes = recipeVM.all.where((r) => !r.urgent).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Matches for you',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPri(context),
                  )),
              const SizedBox(height: 4),
              Text('Recipes that match your selected ingredients.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              ...recipes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecipeMatchCard(recipe: r),
                  )),
            ],
          );
        },
      ),
    );
  }
}
DART

# ---- Favorites screen ------------------------------------------------------
cat > lib/view/screens/recipes/favorites_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/recipe_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';
import 'recipe_match_card.dart';

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
          final favs = recipeVM.favorites;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite,
                      color: AppColors.danger, size: 26),
                  const SizedBox(width: 8),
                  Text('Favorite Recipes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  '${favs.length} recipe${favs.length == 1 ? '' : 's'} saved.',
                  style: TextStyle(
                      color: AppColors.textSec(context), fontSize: 13)),
              const SizedBox(height: 16),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 64, color: AppColors.textMut(context)),
                      const SizedBox(height: 12),
                      Text('No favorites yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSec(context),
                          )),
                      const SizedBox(height: 6),
                      Text('Tap the heart on a recipe to save it here.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMut(context))),
                    ],
                  ),
                )
              else
                ...favs.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecipeMatchCard(recipe: r),
                    )),
            ],
          );
        },
      ),
    );
  }
}
DART

ok "Recipe sub-screens written."

# =============================================================================
# 21. SHOPPING LIST SCREEN
# =============================================================================
info "Writing shopping_list_screen..."

cat > lib/view/screens/shopping/shopping_list_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../model/shopping_item.dart';
import '../../../viewmodel/shopping_vm.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/vm_listener.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

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
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: isDark ? AppColors.primary : AppColors.primaryDark),
            onPressed: () => _addDialog(context),
          ),
        ],
      ),
      body: VMListener(
        listenable: shoppingVM,
        builder: (ctx) {
          final items = shoppingVM.all;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shopping List',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        )),
                    Text(
                        '${items.length} items • ${shoppingVM.checkedCount} ticked',
                        style: TextStyle(
                            color: AppColors.textSec(context), fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Remove',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              shoppingVM.delete(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${item.name} removed.'),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () =>
                                        shoppingVM.add(item),
                                  ),
                                ),
                              );
                            },
                            child: _tile(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: VMListener(
        listenable: shoppingVM,
        builder: (ctx) {
          final count = shoppingVM.checkedCount;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: AppColors.bg(context),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (count == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Tick items first to add them to pantry.')),
                    );
                    return;
                  }
                  final moved = await shoppingVM.moveCheckedToPantry();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('$moved item(s) added to pantry.')),
                    );
                  }
                },
                icon: const Icon(Icons.kitchen),
                label: Text(count > 0
                    ? 'Add $count item(s) to Pantry'
                    : 'Add Checked Items to Pantry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, ShoppingItem item) {
    return InkWell(
      onTap: () => shoppingVM.toggleChecked(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (_) => shoppingVM.toggleChecked(item),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.checked
                          ? AppColors.textMut(context)
                          : AppColors.textPri(context),
                      decoration:
                          item.checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.note != null) ...[
                    const SizedBox(height: 2),
                    Text(item.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: AppColors.textSec(context)),
              onPressed: () => shoppingVM.delete(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textMut(context)),
          const SizedBox(height: 16),
          Text('Your shopping list is empty.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSec(context),
              )),
          const SizedBox(height: 6),
          Text('Tap + to add items.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMut(context))),
        ],
      ),
    );
  }

  void _addDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to Shopping List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(hintText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                Navigator.pop(context);
                return;
              }
              shoppingVM.add(ShoppingItem(
                id: 's_${DateTime.now().microsecondsSinceEpoch}',
                name: name,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
DART
ok "Shopping list written."

# =============================================================================
# 22. PROFILE SCREEN — with Log Out tile
# =============================================================================
info "Writing profile_screen..."

profile_screen.dart

ok "Profile screen written."

# =============================================================================
# 22. EDIT PROFILE + PRIVACY SCREENS
# =============================================================================
info "Writing edit profile + privacy screens..."

# ---- Edit Profile ---------------------------------------------------------
cat > lib/view/screens/misc/edit_profile_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../widgets/app_logo.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl =
      TextEditingController(text: AppStrings.userName);
  final _emailCtrl =
      TextEditingController(text: AppStrings.userEmail);
  final _phoneCtrl = TextEditingController(text: '+977 98XXXXXXXX');
  final _bioCtrl =
      TextEditingController(text: 'Trying to waste less and cook more.');

  bool _currentObscure = true;
  bool _newObscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.chipBg(context),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile/avatar_default.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textMut(context),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Personal info ----
          _sectionLabel('Personal Information'),
          const SizedBox(height: 8),
          _formCard(
            context,
            child: Column(
              children: [
                _field('Full Name', _nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _field('Email Address', _emailCtrl, Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _field('Bio', _bioCtrl, Icons.notes, maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Password ----
          _sectionLabel('Change Password'),
          const SizedBox(height: 8),
          _formCard(
            context,
            child: Column(
              children: [
                TextField(
                  obscureText: _currentObscure,
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_currentObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                          () => _currentObscure = !_currentObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: _newObscure,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_newObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _newObscure = !_newObscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile saved.')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String s) {
    return Text(
      s,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _formCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _field(String hint, TextEditingController c, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
DART

# ---- Privacy --------------------------------------------------------------
cat > lib/view/screens/misc/privacy_screen.dart <<'DART'
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _analytics = true;
  bool _personalized = true;
  bool _location = false;
  bool _crashReports = true;

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Privacy & Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          const SizedBox(height: 14),

          _section(context, 'Data Sharing'),
          _toggleCard(
            context,
            icon: Icons.analytics_outlined,
            title: 'Anonymous Usage Analytics',
            subtitle: 'Help us improve the app',
            value: _analytics,
            onChanged: (v) => setState(() => _analytics = v),
          ),
          _toggleCard(
            context,
            icon: Icons.person_outline,
            title: 'Personalized Recommendations',
            subtitle: 'Based on your pantry & history',
            value: _personalized,
            onChanged: (v) => setState(() => _personalized = v),
          ),
          _toggleCard(
            context,
            icon: Icons.location_on_outlined,
            title: 'Location for Local Recipes',
            subtitle: 'Get region-appropriate ideas',
            value: _location,
            onChanged: (v) => setState(() => _location = v),
          ),
          _toggleCard(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Crash Reports',
            subtitle: 'Send diagnostic data automatically',
            value: _crashReports,
            onChanged: (v) => setState(() => _crashReports = v),
          ),

          const SizedBox(height: 18),
          _section(context, 'Your Data'),
          _navTile(context, Icons.download_outlined, 'Export My Data',
              'Get a copy of everything', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export started…')),
            );
          }),
          _navTile(context, Icons.history, 'Login Activity',
              'Recent sign-ins and devices', () {}),
          _navTile(context, Icons.devices_other, 'Connected Devices',
              '2 active devices', () {}),

          const SizedBox(height: 18),
          _section(context, 'Legal'),
          _navTile(context, Icons.description_outlined, 'Terms of Service',
              null, () {}),
          _navTile(context, Icons.policy_outlined, 'Privacy Policy', null,
              () {}),
          _navTile(context, Icons.gavel, 'Cookie Settings', null, () {}),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showClearDataDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text(
                    'Clear All My Data',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This removes all your pantry items, shopping list, and preferences. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared.')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        s,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _toggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context),
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSec(context), size: 20),
          ],
        ),
      ),
    );
  }
}
DART

ok "Edit profile + privacy screens written."

# =============================================================================
# 23. CLEAN + PUB GET + DART FIX
# =============================================================================
info "Cleaning Flutter build cache (so new MVVM structure is picked up)..."
if command -v flutter >/dev/null 2>&1; then
  flutter clean >/dev/null 2>&1 || warn "flutter clean had issues, continuing..."
  ok "Build cache cleared."
  info "Running flutter pub get..."
  flutter pub get
  ok "Dependencies installed."
else
  warn "flutter command not found. Run: flutter clean && flutter pub get"
fi

info "Running dart fix for any remaining lints..."
if command -v dart >/dev/null 2>&1; then
  dart fix --apply 2>/dev/null || warn "dart fix had warnings — non-fatal."
fi

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  ShelfLife v4 update complete!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo
echo "What's new in v4:"
echo "  ✓ Full MVVM refactor (constants / model / repo / viewmodel / view)"
echo "  ✓ Working password reveal toggles (login + signup + edit profile)"
echo "  ✓ Working birthdate picker on signup step 1"
echo "  ✓ Log Out tile on Profile (returns to Login)"
echo "  ✓ Delete Account now wipes Hive data + returns to Login"
echo "  ✓ Recipe search by name / ingredient / cooking time (collapsible)"
echo "  ✓ Max-time filter chip (Any / 5 / 15 / 30 / 60 min)"
echo "  ✓ Recipe '+ Buy' for ingredients adds to shopping list ('In list' state)"
echo "  ✓ Undo for pantry delete (snackbar UNDO action)"
echo "  ✓ Duplicate-name warning: Cancel / Increase existing / Add anyway"
echo "  ✓ Optional purchase date (drives expiry suggestion when set)"
echo "  ✓ Favorite pantry items (heart on card, Favorites filter chip)"
echo "  ✓ Right-swipe pantry → Mark as Finished (+ optional shopping add)"
echo "  ✓ Finished items grayed out + strikethrough, viewable via Finished chip"
echo "  ✓ Unit dropdown + numeric quantity + auto unit conversion display"
echo "  ✓ Repos: every interface has a paired _impl.dart"
echo
echo "Next steps:"
echo "  1. In Android Studio: File → Invalidate Caches / Restart"
echo "  2. flutter run"
echo
echo "Saving v4 to git:"
echo "  git add ."
echo "  git commit -m \"v4 MVVM refactor + new features\""
echo "  git tag v4"
echo
echo "Rolling back to v3 (if needed):"
echo "  git reset --hard v3"
echo
