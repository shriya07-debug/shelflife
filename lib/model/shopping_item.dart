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
