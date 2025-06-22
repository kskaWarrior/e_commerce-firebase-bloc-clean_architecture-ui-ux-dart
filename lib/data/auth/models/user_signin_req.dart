class UserSigninReq {
  final String email;
  String? password;

  UserSigninReq({
    required this.email,
    this.password
  });
}