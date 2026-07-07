class UserProfile {
  final String name;
  final List<String> dietary;
  final List<String> allergies;
  const UserProfile({
    this.name = '',
    this.dietary = const [],
    this.allergies = const [],
  });
}

abstract class ProfileRepo {
  Future<void> init();
  UserProfile get profile;
  Future<void> save(UserProfile profile);
}
