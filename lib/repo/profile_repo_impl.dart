import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';
import '../model/user_profile.dart';
import 'profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  final _fs = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _fs
      .collection(AppStrings.usersCol)
      .doc(uid)
      .collection(AppStrings.meta)
      .doc(AppStrings.profileDoc);

  @override
  Future<UserProfile?> get(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data() ?? {});
  }

  @override
  Future<void> save(String uid, UserProfile profile) async {
    await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> update(String uid, Map<String, dynamic> fields) async {
    await _doc(uid).set(fields, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String uid) async {
    await _doc(uid).delete();
  }
}
