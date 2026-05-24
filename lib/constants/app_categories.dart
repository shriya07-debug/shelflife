/// Centralized lists used across forms and filters.
class AppCategories {
  AppCategories._();

  /// Categories shown in the Add/Edit form. "Other" is the fallback.
  static const List<String> all = [
    'Dairy',
    'Produce',
    'Meat',
    'Grains',
    'Beverages',
    'Snacks',
    'Other',
  ];

  /// Filter chips on the Pantry screen.
  /// "Favorites" is virtual (a flag on items, not a category).
  /// "Finished" is virtual (a status on items, not a category).
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
