/// Framework-agnostic snapshot of the signed-in user, so the UI/VM layer
/// never has to import FirebaseAuth directly.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  const AuthUser({required this.uid, this.email, this.displayName});
}

/// Thrown for expected auth failures. [message] is safe to show to users.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

abstract class AuthRepo {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> sendPasswordReset(String email);
}
