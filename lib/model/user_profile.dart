class UserProfile {
  final String? displayName;
  final String? email;
  final DateTime? birthdate;
  final String? gender;
  final List<String> dietaryPrefs;
  final List<String> allergies;
  final bool darkMode;

  const UserProfile({
    this.displayName,
    this.email,
    this.birthdate,
    this.gender,
    this.dietaryPrefs = const [],
    this.allergies = const [],
    this.darkMode = false,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'birthdate': birthdate?.toIso8601String(),
        'gender': gender,
        'dietaryPrefs': dietaryPrefs,
        'allergies': allergies,
        'darkMode': darkMode,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        displayName: m['displayName'] as String?,
        email: m['email'] as String?,
        birthdate: m['birthdate'] != null
            ? DateTime.parse(m['birthdate'] as String)
            : null,
        gender: m['gender'] as String?,
        dietaryPrefs:
            List<String>.from((m['dietaryPrefs'] as List?) ?? const []),
        allergies: List<String>.from((m['allergies'] as List?) ?? const []),
        darkMode: (m['darkMode'] as bool?) ?? false,
      );

  UserProfile copyWith({
    String? displayName,
    String? email,
    DateTime? birthdate,
    String? gender,
    List<String>? dietaryPrefs,
    List<String>? allergies,
    bool? darkMode,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        birthdate: birthdate ?? this.birthdate,
        gender: gender ?? this.gender,
        dietaryPrefs: dietaryPrefs ?? this.dietaryPrefs,
        allergies: allergies ?? this.allergies,
        darkMode: darkMode ?? this.darkMode,
      );
}
