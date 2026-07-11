import 'package:flutter/foundation.dart';
import '../repo/auth_repo.dart';
import '../repo/auth_repo_impl.dart';

/// Global auth view-model, matching the app's existing `final xVM = XVM();`
/// convention. Methods return null on success or a user-facing error string.
final authVM = AuthVM();

class AuthVM extends ChangeNotifier {
  final AuthRepo _repo = AuthRepoImpl();

  bool busy = false;

  Stream<AuthUser?> get authState => _repo.authStateChanges();
  AuthUser? get currentUser => _repo.currentUser;

  Future<String?> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email.trim(), password: password));

  Future<String?> signUp(String email, String password, String name) => _run(
      () => _repo.signUp(email: email.trim(), password: password, name: name));

  Future<void> signOut() => _repo.signOut();

  Future<String?> updateDisplayName(String name) =>
      _run(() => _repo.updateDisplayName(name));

  Future<String?> changePassword(String current, String next) =>
      _run(() => _repo.changePassword(current, next));

  Future<String?> deleteAccount() => _run(() => _repo.deleteAccount());

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<String?> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
