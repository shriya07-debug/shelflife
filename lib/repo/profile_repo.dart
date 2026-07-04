import '../model/user_profile.dart';

abstract class ProfileRepo {
  Future<UserProfile?> get(String uid);
  Future<void> save(String uid, UserProfile profile);
  Future<void> update(String uid, Map<String, dynamic> fields);
  Future<void> delete(String uid);
}
