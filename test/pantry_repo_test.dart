import 'package:shelflife/model/pantry_item.dart';
import 'package:shelflife/repo/pantry_repo_firebase_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PantryRepoFirebaseImpl repo;
  const uid = 'test-uid';

  // Helper so we're not repeating the same long constructor everywhere.
  PantryItem makeItem({
    required String id,
    String name = 'Milk',
    String category = 'Dairy',
    double quantity = 1,
    String unitCode = 'l',
    DateTime? expiryDate,
    DateTime? addedDate,
  }) {
    return PantryItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      unitCode: unitCode,
      expiryDate: expiryDate ?? DateTime(2026, 12, 25),
      addedDate: addedDate ?? DateTime(2026, 1, 1),
    );
  }

  // Runs before EVERY test, so each test starts with a clean, empty
  // database and a freshly-initialized repo.
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = PantryRepoFirebaseImpl(uid, firestore: fakeFirestore);
  });

  tearDown(() {
    repo.dispose();
  });

  test('init hydrates the cache from existing Firestore data', () async {
    // Seed data directly, as if it was already there from another device.
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('pantry')
        .doc('1')
        .set(makeItem(id: '1', name: 'Eggs').toMap());

    await repo.init();

    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Eggs');
  });

  test('getAll returns an empty list when there is nothing', () async {
    await repo.init();
    expect(repo.getAll(), isEmpty);
  });

  test('add saves the item locally and in Firestore', () async {
    await repo.init();

    final item = makeItem(id: '1', name: 'Cheese');
    await repo.add(item);

    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Cheese');

    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('pantry')
        .doc('1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Cheese');
  });

  test('add saves multiple items correctly', () async {
    await repo.init();

    await repo.add(makeItem(id: '1', name: 'Milk'));
    await repo.add(makeItem(id: '2', name: 'Bread'));

    final all = repo.getAll();
    expect(all.length, 2);
    expect(all.map((i) => i.name), containsAll(['Milk', 'Bread']));
  });

  test('getById returns the matching item', () async {
    await repo.init();
    await repo.add(makeItem(id: '1', name: 'Yogurt'));

    final found = repo.getById('1');
    expect(found, isNotNull);
    expect(found!.name, 'Yogurt');
  });

  test('getById returns null when the id does not exist', () async {
    await repo.init();
    expect(repo.getById('does-not-exist'), isNull);
  });

  test('update (via add) changes the saved values', () async {
    await repo.init();

    final item = makeItem(id: '1', name: 'Old name', quantity: 1);
    await repo.add(item);

    final updated = item.copyWith(name: 'New name', quantity: 5);
    await repo.update(updated);

    final found = repo.getById('1');
    expect(found!.name, 'New name');
    expect(found.quantity, 5);
  });

  test('delete removes the item locally and in Firestore', () async {
    await repo.init();
    await repo.add(makeItem(id: '1', name: 'Butter'));

    await repo.delete('1');

    expect(repo.getAll(), isEmpty);
    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('pantry')
        .doc('1')
        .get();
    expect(doc.exists, isFalse);
  });

  test('delete on a non-existent id does not throw', () async {
    await repo.init();
    expect(() => repo.delete('does-not-exist'), returnsNormally);
  });

  test('clear removes every item locally and in Firestore', () async {
    await repo.init();
    await repo.add(makeItem(id: '1', name: 'Milk'));
    await repo.add(makeItem(id: '2', name: 'Bread'));

    await repo.clear();

    expect(repo.getAll(), isEmpty);
    final snap = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('pantry')
        .get();
    expect(snap.docs, isEmpty);
  });

  test('items round-trip correctly through toMap/fromMap via storage',
          () async {
        await repo.init();
        final expiry = DateTime(2026, 12, 25);
        final added = DateTime(2026, 1, 1);
        final item = makeItem(
          id: '1',
          name: 'Frozen Peas',
          category: 'Frozen',
          quantity: 2.5,
          unitCode: 'kg',
          expiryDate: expiry,
          addedDate: added,
        );
        await repo.add(item);

        final found = repo.getById('1')!;
        expect(found.category, 'Frozen');
        expect(found.quantity, 2.5);
        expect(found.unitCode, 'kg');
        expect(found.expiryDate, expiry);
        expect(found.addedDate, added);
      });

  test('an external write to Firestore is picked up via the live stream',
          () async {
        await repo.init();

        // Simulate another device/session writing directly to Firestore,
        // bypassing this repo instance entirely.
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('pantry')
            .doc('external-1')
            .set(makeItem(id: 'external-1', name: 'Added elsewhere').toMap());

        // Give the snapshot listener a moment to fire and update the cache.
        await Future.delayed(const Duration(milliseconds: 50));

        final all = repo.getAll();
        expect(all.any((i) => i.id == 'external-1'), isTrue);
      });
}