import 'package:shelflife/repo/profile_repo.dart';
import 'package:shelflife/repo/profile_repo_firebase_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ProfileRepoFirebaseImpl repo;
  const uid = 'test-uid';

  // Runs before EVERY test, so each test starts with a clean, empty
  // database and a freshly-initialized repo.
  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ProfileRepoFirebaseImpl(uid, firestore: fakeFirestore);
  });

  tearDown(() {
    repo.dispose();
  });

  test('profile defaults to an empty UserProfile before init', () {
    // Before init() is called, _cache is the const default.
    expect(repo.profile.name, '');
    expect(repo.profile.dietary, isEmpty);
    expect(repo.profile.allergies, isEmpty);
    expect(repo.profile.phone, '');
    expect(repo.profile.bio, '');
  });

  test('init hydrates the profile from existing Firestore data', () async {
    // Seed data directly, as if it was already there from another device.
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('main')
        .set({
      'name': 'Jane Doe',
      'dietary': ['Vegetarian'],
      'allergies': ['Peanuts'],
      'phone': '555-1234',
      'bio': 'Loves cooking.',
    });

    await repo.init();

    expect(repo.profile.name, 'Jane Doe');
    expect(repo.profile.dietary, ['Vegetarian']);
    expect(repo.profile.allergies, ['Peanuts']);
    expect(repo.profile.phone, '555-1234');
    expect(repo.profile.bio, 'Loves cooking.');
  });

  test('init falls back to an empty UserProfile when no doc exists',
          () async {
        await repo.init();

        expect(repo.profile.name, '');
        expect(repo.profile.dietary, isEmpty);
        expect(repo.profile.allergies, isEmpty);
      });

  test('save updates the cache and persists to Firestore', () async {
    await repo.init();

    const updated = UserProfile(
      name: 'John Smith',
      dietary: ['Vegan', 'Gluten-Free'],
      allergies: ['Shellfish'],
      phone: '555-9876',
      bio: 'Home chef.',
    );
    await repo.save(updated);

    // Cache reflects it immediately.
    expect(repo.profile.name, 'John Smith');
    expect(repo.profile.dietary, ['Vegan', 'Gluten-Free']);

    // And it's actually persisted in the (fake) database.
    final doc = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('main')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['name'], 'John Smith');
    expect(doc.data()!['allergies'], ['Shellfish']);
  });

  test('an external write to Firestore is picked up via the live stream',
          () async {
        await repo.init();

        // Simulate another device/session updating the profile directly,
        // bypassing this repo instance entirely.
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .collection('profile')
            .doc('main')
            .set({
          'name': 'Updated Elsewhere',
          'dietary': [],
          'allergies': [],
          'phone': '',
          'bio': '',
        });

        // Give the snapshot listener a moment to fire and update the cache.
        await Future.delayed(const Duration(milliseconds: 50));

        expect(repo.profile.name, 'Updated Elsewhere');
      });

  group('writeFor (static, pre-signup helper)', () {
    test('writes a profile for a uid without needing a bound instance',
            () async {
          const newUserProfile = UserProfile(name: 'Brand New User');

          await ProfileRepoFirebaseImpl.writeFor(
            'new-uid',
            newUserProfile,
            firestore: fakeFirestore,
          );

          final doc = await fakeFirestore
              .collection('users')
              .doc('new-uid')
              .collection('profile')
              .doc('main')
              .get();
          expect(doc.exists, isTrue);
          expect(doc.data()!['name'], 'Brand New User');
        });
  });

  group('purgeFor (static, account deletion helper)', () {
    test('deletes both the profile doc and the meta/flags doc', () async {
      const deleteUid = 'delete-uid';
      await fakeFirestore
          .collection('users')
          .doc(deleteUid)
          .collection('profile')
          .doc('main')
          .set({'name': 'To Be Deleted'});
      await fakeFirestore
          .collection('users')
          .doc(deleteUid)
          .collection('meta')
          .doc('flags')
          .set({'firstLaunch': false});

      await ProfileRepoFirebaseImpl.purgeFor(deleteUid, firestore: fakeFirestore);

      final profileDoc = await fakeFirestore
          .collection('users')
          .doc(deleteUid)
          .collection('profile')
          .doc('main')
          .get();
      final flagsDoc = await fakeFirestore
          .collection('users')
          .doc(deleteUid)
          .collection('meta')
          .doc('flags')
          .get();

      expect(profileDoc.exists, isFalse);
      expect(flagsDoc.exists, isFalse);
    });

    test('does not throw when there is nothing to delete', () async {
      expect(
            () => ProfileRepoFirebaseImpl.purgeFor('never-existed-uid',
            firestore: fakeFirestore),
        returnsNormally,
      );
    });
  });
}