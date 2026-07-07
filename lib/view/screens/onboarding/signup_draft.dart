/// Carries signup form data from step 1 through to account creation in step 3.
class SignupDraft {
  SignupDraft._();
  static final SignupDraft i = SignupDraft._();

  String name = '';
  String email = '';
  String password = '';
  String birthday = '';
  List<String> dietary = [];
  List<String> allergies = [];

  void clear() {
    name = '';
    email = '';
    password = '';
    birthday = '';
    dietary = [];
    allergies = [];
  }
}
