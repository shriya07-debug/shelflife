import 'package:firebase_auth/firebase_auth.dart';

/// Auth contract used by AuthVM.
abstract class AuthRepo {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<User?> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);
  Future<void> updateDisplayName(String name);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();
  Future<void> deleteAccount();
}
