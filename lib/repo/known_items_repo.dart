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
