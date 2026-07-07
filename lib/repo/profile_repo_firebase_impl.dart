import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_repo.dart';

/// Firestore-backed profile at users/{uid}/profile/main.
class ProfileRepoFirebaseImpl implements ProfileRepo {
  ProfileRepoFirebaseImpl(this.uid);
  final String uid;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('profile')
      .doc('main');

  UserProfile _cache = const UserProfile();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  static UserProfile _fromMap(Map<String, dynamic>? m) {
    if (m == null) return const UserProfile();
    return UserProfile(
      name: (m['name'] as String?) ?? '',
      dietary: ((m['dietary'] as List?) ?? const []).map((e) => '$e').toList(),
      allergies:
          ((m['allergies'] as List?) ?? const []).map((e) => '$e').toList(),
    );
  }

  static Map<String, dynamic> _toMap(UserProfile p) =>
      {'name': p.name, 'dietary': p.dietary, 'allergies': p.allergies};

  @override
  Future<void> init() async {
    _cache = _fromMap((await _doc.get()).data());
    _sub = _doc.snapshots().listen(
      (snap) => _cache = _fromMap(snap.data()),
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  UserProfile get profile => _cache;

  @override
  Future<void> save(UserProfile profile) async {
    _cache = profile;
    await _doc.set(_toMap(profile));
  }

  /// Write a profile for [uid] without needing a bound instance (used at signup,
  /// before the service locator has bound the new user).
  static Future<void> writeFor(String uid, UserProfile p) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('profile')
      .doc('main')
      .set(_toMap(p));

  /// Delete the profile + first-launch flag for [uid] (account deletion).
  static Future<void> purgeFor(String uid) async {
    final u = FirebaseFirestore.instance.collection('users').doc(uid);
    await u.collection('meta').doc('flags').delete();
    await u.collection('profile').doc('main').delete();
  }
}
