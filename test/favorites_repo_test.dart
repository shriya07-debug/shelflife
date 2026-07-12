import 'package:shelflife/repo/favorites_repo_firebase_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FavoritesRepoFirebaseImpl repo;
  const uid = 'test-uid';

  // Runs before EVERY test, so each test starts with a clean, empty
  // database and a freshly-initialized repo.
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FavoritesRepoFirebaseImpl(uid, firestore: fakeFirestore);
  });

  tearDown(() {
    repo.dispose();
  });

  test('init hydrates favorites from existing Firestore data', () async {
    // Seed data directly, as if it was already there from another device.
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('r_1')
        .set({'fav': true});

    await repo.init();

    expect(repo.getAll(), {'r_1'});
    expect(repo.isFavorite('r_1'), isTrue);
  });

  test('getAll returns an empty set when there is nothing', () async {
    await repo.init();
    expect(repo.getAll(), isEmpty);
  });

  test('isFavorite returns false for a recipe that was never favorited',
          () async {
        await repo.init();
        expect(repo.isFavorite('r_1'), isFalse);
      });

  test('toggle adds a recipe locally and in Firestore', () async {
    await repo.init();

    await repo.toggle('r_1');

    expect(repo.isFavorite('r_1'), isTrue);
    expect(repo.getAll(), contains('r_1'));

    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('r_1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['fav'], isTrue);
  });

  test('toggle again removes it locally and in Firestore', () async {
    await repo.init();

    await repo.toggle('r_1'); // add
    await repo.toggle('r_1'); // remove

    expect(repo.isFavorite('r_1'), isFalse);
    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc('r_1')
        .get();
    expect(doc.exists, isFalse);
  });

  test('toggle only affects the given recipe id', () async {
    await repo.init();

    await repo.toggle('r_1');
    await repo.toggle('r_2');
    await repo.toggle('r_1'); // remove r_1, leave r_2

    expect(repo.isFavorite('r_1'), isFalse);
    expect(repo.isFavorite('r_2'), isTrue);
    expect(repo.getAll(), {'r_2'});
  });

  test('getAll reflects multiple favorited recipes', () async {
    await repo.init();

    await repo.toggle('r_1');
    await repo.toggle('r_2');
    await repo.toggle('r_3');

    final all = repo.getAll();
    expect(all.length, 3);
    expect(all, containsAll(['r_1', 'r_2', 'r_3']));
  });

  test('clear removes every favorite locally and in Firestore', () async {
    await repo.init();
    await repo.toggle('r_1');
    await repo.toggle('r_2');

    await repo.clear();

    expect(repo.getAll(), isEmpty);
    final snap = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();
    expect(snap.docs, isEmpty);
  });

  test('an external write to Firestore is picked up via the live stream',
          () async {
        await repo.init();

        // Simulate another device/session favoriting a recipe directly,
        // bypassing this repo instance entirely.
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc('external-1')
            .set({'fav': true});

        // Give the snapshot listener a moment to fire and update the cache.
        await Future.delayed(const Duration(milliseconds: 50));

        expect(repo.isFavorite('external-1'), isTrue);
      });
}