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
    const months = [
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
