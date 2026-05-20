import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/auth/signin_lockout_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const email = 'John@Doe.com';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getStatus returns unlocked when there is no lock state', () async {
    final store = SigninLockoutStore();

    final status = await store.getStatus(email);

    expect(status.isLocked, isFalse);
    expect(status.failedAttempts, 0);
    expect(status.remaining, Duration.zero);
  });

  test('registerInvalidAttempt locks after max attempts', () async {
    final store = SigninLockoutStore();

    for (var i = 0; i < SigninLockoutStore.maxAttempts - 1; i++) {
      final locked = await store.registerInvalidAttempt(email);
      expect(locked, isFalse);
    }

    final lockedOnLimit = await store.registerInvalidAttempt(email);
    final status = await store.getStatus(email);

    expect(lockedOnLimit, isTrue);
    expect(status.isLocked, isTrue);
    expect(status.failedAttempts, SigninLockoutStore.maxAttempts);
  });

  test('clearAttempts resets lock and attempts', () async {
    final store = SigninLockoutStore();

    for (var i = 0; i < SigninLockoutStore.maxAttempts; i++) {
      await store.registerInvalidAttempt(email);
    }

    await store.clearAttempts(email);
    final status = await store.getStatus(email);

    expect(status.isLocked, isFalse);
    expect(status.failedAttempts, 0);
  });

  test('formatLockoutRemaining formats values as expected', () {
    expect(formatLockoutRemaining(Duration.zero), '0m');
    expect(formatLockoutRemaining(const Duration(seconds: 20)), '20s');
    expect(formatLockoutRemaining(const Duration(minutes: 2)), '2m');
    expect(formatLockoutRemaining(const Duration(minutes: 1, seconds: 5)), '1m 5s');
  });
}
