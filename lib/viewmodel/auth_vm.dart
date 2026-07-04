import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/user_profile.dart';
import '../repo/services.dart';
import '../repo/sync_service.dart';
import 'pantry_vm.dart';
import 'shopping_vm.dart';
import 'recipe_vm.dart';
import 'home_vm.dart';

class AuthVM extends ChangeNotifier {
  User? _user;
  bool _busy = false;
  String? _error;
  UserProfile? _profile;

  User? get currentUser => _user;
  bool get busy => _busy;
  String? get error => _error;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _user != null;

  Stream<User?> get authStateChanges => Services.auth.authStateChanges;

  AuthVM() {
    _user = Services.auth.currentUser;
    Services.auth.authStateChanges.listen((u) {
      _user = u;
      notifyListeners();
      if (u != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      _profile = await Services.profile.get(_user!.uid);
      notifyListeners();
    } catch (_) {
      // Non-fatal
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    DateTime? birthdate,
    String? gender,
    List<String> dietaryPrefs = const [],
    List<String> allergies = const [],
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await Services.auth.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (u == null) throw Exception('Signup returned null user');
      _user = u;

      // Save profile
      final prof = UserProfile(
        displayName: displayName,
        email: email,
        birthdate: birthdate,
        gender: gender,
        dietaryPrefs: dietaryPrefs,
        allergies: allergies,
        darkMode: Services.settings.darkMode,
      );
      await Services.profile.save(u.uid, prof);
      _profile = prof;

      // Upload guest Hive data to cloud, rebind repos
      await syncService.onLogin(u.uid, wasSignUp: true);
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();

      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final u = await Services.auth.signIn(email: email, password: password);
      if (u == null) throw Exception('Signin returned null user');
      _user = u;

      await syncService.onLogin(u.uid, wasSignUp: false);
      await _loadProfile();
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();

      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await Services.auth.sendPasswordReset(email);
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await Services.auth.signOut();
    await syncService.onLogout();
    _profile = null;
    // notify — repos have been rebound
    pantryVM.notifyListeners();
    shoppingVM.notifyListeners();
    recipeVM.notifyListeners();
    homeVM.notifyListeners();
  }

  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _user!.uid;
      await syncService.deleteAllUserData(uid);
      await Services.auth.deleteAccount();
      await syncService.onLogout();
      _profile = null;
      pantryVM.notifyListeners();
      shoppingVM.notifyListeners();
      recipeVM.notifyListeners();
      homeVM.notifyListeners();
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_user == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await Services.auth.updatePassword(newPassword);
      _busy = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _prettyError(e);
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveProfile(UserProfile updated) async {
    if (_user == null) return;
    await Services.profile.save(_user!.uid, updated);
    _profile = updated;
    notifyListeners();
  }

  String _prettyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to do this.';
      default:
        return e.message ?? e.code;
    }
  }
}

final authVM = AuthVM();
