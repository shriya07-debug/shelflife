class SignupState {
  String? name;
  String? email;
  String? password;
  DateTime? birthdate;
  String? gender;
  List<String> dietaryPrefs = [];
  List<String> allergies = [];

  void reset() {
    name = null;
    email = null;
    password = null;
    birthdate = null;
    gender = null;
    dietaryPrefs = [];
    allergies = [];
  }
}

final signupState = SignupState();
