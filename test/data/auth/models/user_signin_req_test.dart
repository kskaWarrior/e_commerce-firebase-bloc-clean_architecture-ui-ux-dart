import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores email and optional password', () {
    final request = UserSigninReq(email: 'john@doe.com', password: 'secret');

    expect(request.email, 'john@doe.com');
    expect(request.password, 'secret');
  });

  test('allows null password', () {
    final request = UserSigninReq(email: 'john@doe.com');

    expect(request.email, 'john@doe.com');
    expect(request.password, isNull);
  });
}
