import 'dart:convert';
import 'package:http/http.dart' as http;

/// A product resolved from Open Food Facts (or the Firestore cache).
class ScannedProduct {
  final String barcode;
  final String name;
  final String category; // mapped to AppCategories
  final int shelfLifeDays; // estimated
  final String? imageUrl;
  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.category,
    required this.shelfLifeDays,
    this.imageUrl,
  });
}

/// Open Food Facts lookup + category/shelf-life heuristics.
class OffService {
  OffService._();

  static const Map<String, int> _shelfLife = {
    'Dairy': 10,
    'Produce': 6,
    'Meat': 4,
    'Grains': 120,
    'Beverages': 90,
    'Snacks': 120,
    'Other': 30,
  };

  static int shelfLifeFor(String category) => _shelfLife[category] ?? 30;

  /// Maps OFF's free-form categories onto the app's fixed AppCategories list.
  static String mapCategory(String raw) {
    final t = raw.toLowerCase();
    bool has(List<String> ks) => ks.any(t.contains);
    if (has(['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'dairy'])) {
      return 'Dairy';
    }
    if (has(['fruit', 'vegetable', 'produce', 'fresh'])) return 'Produce';
    if (has(['meat', 'chicken', 'beef', 'pork', 'fish', 'seafood', 'poultry',
        'sausage'])) {
      return 'Meat';
    }
    if (has(['bread', 'cereal', 'rice', 'pasta', 'grain', 'flour', 'bakery',
        'noodle'])) {
      return 'Grains';
    }
    if (has(['beverage', 'drink', 'juice', 'water', 'soda', 'tea', 'coffee',
        'smoothie'])) {
      return 'Beverages';
    }
    if (has(['snack', 'chip', 'candy', 'chocolate', 'biscuit', 'cookie',
        'sweet', 'confection'])) {
      return 'Snacks';
    }
    return 'Other';
  }

  /// Looks up a barcode on Open Food Facts. Returns null if not found/unknown.
  static Future<ScannedProduct?> lookup(String barcode) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,brands,categories,image_url');
    try {
      final res = await http.get(uri,
          headers: {'User-Agent': 'ShelfLife/6.0 (Flutter app)'});
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null; // 1 = product found
      final p = body['product'] as Map<String, dynamic>?;
      if (p == null) return null;
      final name = (p['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;
      final category = mapCategory((p['categories'] as String?) ?? '');
      return ScannedProduct(
        barcode: barcode,
        name: name,
        category: category,
        shelfLifeDays: shelfLifeFor(category),
        imageUrl: p['image_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
