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
