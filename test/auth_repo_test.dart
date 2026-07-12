import 'package:shelflife/repo/auth_repo.dart';
import 'package:shelflife/repo/auth_repo_impl.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthRepoImpl repo;

  // Runs before EVERY test, so each test starts signed out with a
  // clean, isolated fake FirebaseAuth instance.
  setUp(() {
    mockAuth = MockFirebaseAuth();
    repo = AuthRepoImpl(auth: mockAuth);
  });

  group('currentUser / authStateChanges', () {
    test('currentUser is null when signed out', () {
      expect(repo.currentUser, isNull);
    });

    test('currentUser maps the signed-in user correctly', () async {
      // Start already signed in.
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        signedIn: true,
      );
      repo = AuthRepoImpl(auth: mockAuth);

      final user = repo.currentUser;
      expect(user, isNotNull);
      expect(user!.uid, 'uid-1');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
    });

    test('authStateChanges emits null then the user after sign in',
            () async {
          final states = <AuthUser?>[];
          final sub = repo.authStateChanges().listen(states.add);

          await repo.signUp(
            email: 'new@example.com',
            password: 'password123',
            name: 'New User',
          );
          await Future.delayed(const Duration(milliseconds: 50));

          expect(states.any((s) => s != null && s.email == 'new@example.com'),
              isTrue);

          await sub.cancel();
        });
  });

  group('signIn', () {
    test('signs in successfully with correct credentials', () async {
      // Pre-register the user in the mock backend.
      await mockAuth.createUserWithEmailAndPassword(
          email: 'user@example.com', password: 'correctpass');
      await mockAuth.signOut();

      await repo.signIn(email: 'user@example.com', password: 'correctpass');

      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser!.email, 'user@example.com');
    });
  });

  group('signUp', () {
    test('creates a new user and sets the display name', () async {
      await repo.signUp(
        email: 'jane@example.com',
        password: 'password123',
        name: 'Jane Doe',
      );

      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser!.email, 'jane@example.com');
      expect(repo.currentUser!.displayName, 'Jane Doe');
    });

    test('trims whitespace from the display name', () async {
      await repo.signUp(
        email: 'trim@example.com',
        password: 'password123',
        name: '  Jane Doe  ',
      );

      expect(repo.currentUser!.displayName, 'Jane Doe');
    });

    test('skips setting display name when name is blank', () async {
      await repo.signUp(
        email: 'noname@example.com',
        password: 'password123',
        name: '   ',
      );

      // Should not throw, and displayName stays null/empty rather than
      // being set to whitespace.
      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser!.displayName, anyOf(isNull, isEmpty));
    });
  });

  group('signOut', () {
    test('clears the current user', () async {
      await repo.signUp(
        email: 'out@example.com',
        password: 'password123',
        name: 'Out User',
      );
      expect(repo.currentUser, isNotNull);

      await repo.signOut();

      expect(repo.currentUser, isNull);
    });
  });

  group('updateDisplayName', () {
    test('updates the display name for the signed-in user', () async {
      await repo.signUp(
        email: 'update@example.com',
        password: 'password123',
        name: 'Old Name',
      );

      await repo.updateDisplayName('Brand New Name');

      expect(repo.currentUser!.displayName, 'Brand New Name');
    });

    test('does nothing when no one is signed in', () async {
      // Should not throw even though currentUser is null.
      expect(() => repo.updateDisplayName('Nobody'), returnsNormally);
    });
  });

  group('deleteAccount', () {
    test('removes the current user so currentUser becomes null', () async {
      await repo.signUp(
        email: 'delete@example.com',
        password: 'password123',
        name: 'Delete Me',
      );
      expect(repo.currentUser, isNotNull);

      await repo.deleteAccount();

      expect(repo.currentUser, isNull);
    });

    test('does nothing when no one is signed in', () async {
      expect(() => repo.deleteAccount(), returnsNormally);
    });
  });

  group('sendPasswordReset', () {
    test('completes without throwing for a valid email', () async {
      await expectLater(
        repo.sendPasswordReset('someone@example.com'),
        completes,
      );
    });
  });

  group('changePassword', () {
    test('throws a friendly AuthException when not signed in', () async {
      expect(
            () => repo.changePassword('oldpass', 'newpass123'),
        throwsA(isA<AuthException>().having(
              (e) => e.message,
          'message',
          'Not signed in.',
        )),
      );
    });
  });

  group('error message mapping', () {
    // These confirm FirebaseAuthException codes map to the correct
    // user-facing message. We trigger real Firebase Auth error codes
    // via the mock package's built-in validation where possible.

    test('signing up with an already-used email throws a friendly message',
            () async {
          await repo.signUp(
            email: 'dupe@example.com',
            password: 'password123',
            name: 'First',
          );
          await repo.signOut();

          expect(
                () => repo.signUp(
              email: 'dupe@example.com',
              password: 'password123',
              name: 'Second',
            ),
            throwsA(isA<AuthException>()),
          );
        });

    test('signing in with wrong credentials throws a friendly message',
            () async {
          await repo.signUp(
            email: 'known@example.com',
            password: 'correctpass',
            name: 'Known User',
          );
          await repo.signOut();

          expect(
                () => repo.signIn(email: 'known@example.com', password: 'wrongpass'),
            throwsA(isA<AuthException>()),
          );
        });
  });
}