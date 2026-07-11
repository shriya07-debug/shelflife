class UserProfile {
  final String name;
  final List<String> dietary;
  final List<String> allergies;
  final String phone;
  final String bio;
  const UserProfile({
    this.name = '',
    this.dietary = const [],
    this.allergies = const [],
    this.phone = '',
    this.bio = '',
  });
}

abstract class ProfileRepo {
  Future<void> init();
  UserProfile get profile;
  Future<void> save(UserProfile profile);
}
