import 'package:shelflife/model/enums.dart';
import 'package:shelflife/model/pantry_item.dart';
import 'package:shelflife/viewmodel/add_item_vm.dart';
import 'package:shelflife/viewmodel/pantry_vm.dart';
import 'package:flutter_test/flutter_test.dart';

/// A lightweight stand-in for PantryVM that avoids touching the real
/// Services.pantry singleton (which isn't set up in a unit test).
/// Only overrides findDuplicate(), since that's all AddItemVM calls.
class FakePantryVM extends PantryVM {
  FakePantryVM(this._duplicate);
  final PantryItem? _duplicate;

  @override
  PantryItem? findDuplicate(String name) => _duplicate;
}

void main() {
  group('form field updates', () {
    late AddItemVM vm;

    setUp(() {
      vm = AddItemVM();
    });

    test('has sensible defaults', () {
      expect(vm.name, '');
      expect(vm.quantity, 1);
      expect(vm.unitCode, 'unit');
      expect(vm.category, 'Other');
      expect(vm.expiry, isNull);
      expect(vm.purchaseDate, isNull);
      expect(vm.storage, StorageLocation.fridge);
    });

    test('update() only changes the fields that are passed', () {
      vm.update(name: 'Milk', quantity: 2);

      expect(vm.name, 'Milk');
      expect(vm.quantity, 2);
      // Untouched fields keep their defaults.
      expect(vm.unitCode, 'unit');
      expect(vm.category, 'Other');
    });

    test('update() notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);

      vm.update(name: 'Eggs');

      expect(notified, isTrue);
    });

    test('update() can set every field at once', () {
      final expiry = DateTime(2026, 12, 25);
      final purchase = DateTime(2026, 12, 1);

      vm.update(
        name: 'Cheese',
        quantity: 3,
        unitCode: 'kg',
        category: 'Dairy',
        expiry: expiry,
        purchaseDate: purchase,
        storage: StorageLocation.freezer,
      );

      expect(vm.name, 'Cheese');
      expect(vm.quantity, 3);
      expect(vm.unitCode, 'kg');
      expect(vm.category, 'Dairy');
      expect(vm.expiry, expiry);
      expect(vm.purchaseDate, purchase);
      expect(vm.storage, StorageLocation.freezer);
    });

    test('clearExpiry() sets expiry back to null', () {
      vm.update(expiry: DateTime(2026, 12, 25));
      expect(vm.expiry, isNotNull);

      vm.clearExpiry();

      expect(vm.expiry, isNull);
    });

    test('clearPurchase() sets purchaseDate back to null', () {
      vm.update(purchaseDate: DateTime(2026, 12, 1));
      expect(vm.purchaseDate, isNotNull);

      vm.clearPurchase();

      expect(vm.purchaseDate, isNull);
    });

    test('reset() restores every field to its default', () {
      vm.update(
        name: 'Cheese',
        quantity: 3,
        unitCode: 'kg',
        category: 'Dairy',
        expiry: DateTime(2026, 12, 25),
        purchaseDate: DateTime(2026, 12, 1),
        storage: StorageLocation.freezer,
      );

      vm.reset();

      expect(vm.name, '');
      expect(vm.quantity, 1);
      expect(vm.unitCode, 'unit');
      expect(vm.category, 'Other');
      expect(vm.expiry, isNull);
      expect(vm.purchaseDate, isNull);
      expect(vm.storage, StorageLocation.fridge);
    });
  });

  group('applySuggestion', () {
    late AddItemVM vm;

    setUp(() {
      vm = AddItemVM();
    });

    test('suggests N days from now when purchaseDate is not set', () {
      final before = DateTime.now();
      vm.applySuggestion(3);
      final after = DateTime.now();

      // expiry should be ~3 days from "now" at call time — check it
      // falls within the window bounded by before/after (both +3 days).
      expect(
        vm.expiry!.isAfter(before.add(const Duration(days: 3)).subtract(
            const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        vm.expiry!.isBefore(
            after.add(const Duration(days: 3)).add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('suggests N days after purchaseDate when it is set', () {
      final purchase = DateTime(2026, 1, 1);
      vm.update(purchaseDate: purchase);

      vm.applySuggestion(5);

      expect(vm.expiry, DateTime(2026, 1, 6));
    });

    test('notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);

      vm.applySuggestion(3);

      expect(notified, isTrue);
    });
  });

  group('buildItem', () {
    late AddItemVM vm;

    setUp(() {
      vm = AddItemVM();
    });

    test('trims the name', () {
      vm.update(name: '  Milk  ');
      final item = vm.buildItem();

      expect(item.name, 'Milk');
    });

    test('defaults expiry to 7 days from now when not set', () {
      final before = DateTime.now();
      final item = vm.buildItem();
      final after = DateTime.now();

      expect(
        item.expiryDate.isAfter(
            before.add(const Duration(days: 7)).subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        item.expiryDate.isBefore(
            after.add(const Duration(days: 7)).add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('uses the explicitly set expiry when provided', () {
      final expiry = DateTime(2026, 12, 25);
      vm.update(name: 'Cake', expiry: expiry);

      final item = vm.buildItem();

      expect(item.expiryDate, expiry);
    });

    test('defaults purchaseDate to now when not set', () {
      final before = DateTime.now();
      final item = vm.buildItem();
      final after = DateTime.now();

      expect(item.purchaseDate!.isAfter(before.subtract(const Duration(seconds: 2))),
          isTrue);
      expect(item.purchaseDate!.isBefore(after.add(const Duration(seconds: 2))),
          isTrue);
    });

    test('carries over category, quantity, unitCode, and storage', () {
      vm.update(
        name: 'Yogurt',
        quantity: 4,
        unitCode: 'cup',
        category: 'Dairy',
        storage: StorageLocation.fridge,
      );

      final item = vm.buildItem();

      expect(item.category, 'Dairy');
      expect(item.quantity, 4);
      expect(item.unitCode, 'cup');
      expect(item.storage, StorageLocation.fridge);
    });

    test('generates a non-empty, prefixed id', () {
      final item = vm.buildItem();
      expect(item.id, startsWith('p_'));
      expect(item.id.length, greaterThan(2));
    });
  });

  group('findDuplicate', () {
    test('returns null when the injected PantryVM finds no duplicate', () {
      final vm = AddItemVM(pantryVm: FakePantryVM(null));
      vm.update(name: 'Milk');

      expect(vm.findDuplicate(), isNull);
    });

    test('returns the item when the injected PantryVM finds a duplicate',
            () {
          final existing = PantryItem(
            id: 'p_1',
            name: 'Milk',
            category: 'Dairy',
            quantity: 1,
            unitCode: 'l',
            expiryDate: DateTime(2026, 12, 25),
            addedDate: DateTime(2026, 1, 1),
          );
          final vm = AddItemVM(pantryVm: FakePantryVM(existing));
          vm.update(name: 'Milk');

          final found = vm.findDuplicate();
          expect(found, isNotNull);
          expect(found!.id, 'p_1');
        });
  });
}
