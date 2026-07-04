/// Carries signup form data from step 1 to the account-creation call in
/// step 3. Intentionally tiny; cleared once the account is created.
class SignupDraft {
  SignupDraft._();
  static final SignupDraft i = SignupDraft._();

  String name = '';
  String email = '';
  String password = '';
  String birthday = '';

  void clear() {
    name = '';
    email = '';
    password = '';
    birthday = '';
  }
}
