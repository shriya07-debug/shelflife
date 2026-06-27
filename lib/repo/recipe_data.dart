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
