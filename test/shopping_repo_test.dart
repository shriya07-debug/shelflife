import 'package:shelflife/model/shopping_item.dart';
import 'package:shelflife/repo/shopping_repo_firebase_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ShoppingRepoFirebaseImpl repo;
  const uid = 'test-uid';

  // Runs before EVERY test, so each test starts with a clean, empty
  // database and a freshly-initialized repo.
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ShoppingRepoFirebaseImpl(uid, firestore: fakeFirestore);
  });

  tearDown(() {
    repo.dispose();
  });

  test('init hydrates the cache from existing Firestore data', () async {
    // Seed data directly, as if it was already there from another device.
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('shopping')
        .doc('1')
        .set({'id': '1', 'name': 'Milk', 'note': null, 'checked': false});

    await repo.init();

    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Milk');
  });

  test('getAll returns an empty list when there is nothing', () async {
    await repo.init();
    expect(repo.getAll(), isEmpty);
  });

  test('add saves the item locally and in Firestore', () async {
    await repo.init();

    final item = ShoppingItem(id: '1', name: 'Eggs');
    await repo.add(item);

    // Reflected immediately in the local cache.
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Eggs');

    // And actually persisted in the (fake) database.
    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('shopping')
        .doc('1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'Eggs');
  });

  test('add saves multiple items correctly', () async {
    await repo.init();

    await repo.add(ShoppingItem(id: '1', name: 'Milk'));
    await repo.add(ShoppingItem(id: '2', name: 'Bread'));

    final all = repo.getAll();
    expect(all.length, 2);
    expect(all.map((i) => i.name), containsAll(['Milk', 'Bread']));
  });

  test('update (via add) changes the saved values', () async {
    await repo.init();

    final item = ShoppingItem(id: '1', name: 'Old name', checked: false);
    await repo.add(item);

    item.name = 'New name';
    item.checked = true;
    await repo.update(item);

    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'New name');
    expect(all.first.checked, isTrue);
  });

  test('delete removes the item locally and in Firestore', () async {
    await repo.init();
    await repo.add(ShoppingItem(id: '1', name: 'Yogurt'));

    await repo.delete('1');

    expect(repo.getAll(), isEmpty);
    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('shopping')
        .doc('1')
        .get();
    expect(doc.exists, isFalse);
  });

  test('clear removes every item locally and in Firestore', () async {
    await repo.init();
    await repo.add(ShoppingItem(id: '1', name: 'Milk'));
    await repo.add(ShoppingItem(id: '2', name: 'Bread'));

    await repo.clear();

    expect(repo.getAll(), isEmpty);
    final snap = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('shopping')
        .get();
    expect(snap.docs, isEmpty);
  });

  test('note defaults to null and checked defaults to false', () async {
    await repo.init();
    await repo.add(ShoppingItem(id: '1', name: 'Simple item'));

    final saved = repo.getAll().first;
    expect(saved.note, isNull);
    expect(saved.checked, isFalse);
  });

  test('items round-trip correctly through toMap/fromMap via storage',
          () async {
        await repo.init();
        final item = ShoppingItem(
          id: '1',
          name: 'Butter',
          note: 'Unsalted, if possible',
          checked: true,
        );
        await repo.add(item);

        final saved = repo.getAll().first;
        expect(saved.name, 'Butter');
        expect(saved.note, 'Unsalted, if possible');
        expect(saved.checked, isTrue);
      });

  test('an external write to Firestore is picked up via the live stream',
          () async {
        await repo.init();

        // Simulate another device/session writing directly to Firestore,
        // bypassing this repo instance entirely.
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('shopping')
            .doc('external-1')
            .set({
          'id': 'external-1',
          'name': 'Added elsewhere',
          'note': null,
          'checked': false,
        });

        // Give the snapshot listener a moment to fire and update the cache.
        await Future.delayed(const Duration(milliseconds: 50));

        final all = repo.getAll();
        expect(all.any((i) => i.id == 'external-1'), isTrue);
      });
}