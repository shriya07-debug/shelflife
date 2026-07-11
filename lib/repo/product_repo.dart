import '../service/off_service.dart';

/// Shared, barcode-keyed cache of resolved products (foundation from v5.1a).
abstract class ProductRepo {
  /// Returns the cached product for [barcode], or null if not cached.
  Future<ScannedProduct?> getCached(String barcode);

  /// Stores a resolved product in the shared cache.
  Future<void> cache(ScannedProduct product);
}
