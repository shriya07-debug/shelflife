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
