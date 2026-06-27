/// All app-wide enums in one file.
library;

enum ExpiryStatus { safe, soon, expired }

enum ItemStatus { active, finished }

extension ItemStatusX on ItemStatus {
  String get serialized => name;
  static ItemStatus parse(String? s) {
    return s == 'finished' ? ItemStatus.finished : ItemStatus.active;
  }
}

enum StorageLocation { fridge, freezer, pantry }

extension StorageLocationX on StorageLocation {
  String get label {
    switch (this) {
      case StorageLocation.fridge: return 'Fridge';
      case StorageLocation.freezer: return 'Freezer';
      case StorageLocation.pantry: return 'Pantry';
    }
  }
  static StorageLocation parse(String? s) {
    switch (s) {
      case 'freezer': return StorageLocation.freezer;
      case 'pantry':  return StorageLocation.pantry;
      default:        return StorageLocation.fridge;
    }
  }
  String get serialized => name;
}
