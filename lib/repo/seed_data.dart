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
