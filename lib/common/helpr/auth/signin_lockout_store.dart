import 'package:shared_preferences/shared_preferences.dart';

class SigninLockoutStatus {
  final bool isLocked;
  final Duration remaining;
  final int failedAttempts;

  const SigninLockoutStatus({
    required this.isLocked,
    required this.remaining,
    required this.failedAttempts,
  });
}

class SigninLockoutStore {
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 15);
  static const String _attemptsPrefix = 'signin_failed_attempts_';
  static const String _lockedUntilPrefix = 'signin_locked_until_';

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _attemptsKey(String email) => '$_attemptsPrefix${_normalizeEmail(email)}';
  String _lockedUntilKey(String email) =>
      '$_lockedUntilPrefix${_normalizeEmail(email)}';

  Future<SigninLockoutStatus> getStatus(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    final attempts = prefs.getInt(_attemptsKey(normalizedEmail)) ?? 0;
    final lockedUntilMillis =
        prefs.getInt(_lockedUntilKey(normalizedEmail));

    if (lockedUntilMillis == null) {
      return SigninLockoutStatus(
        isLocked: false,
        remaining: Duration.zero,
        failedAttempts: attempts,
      );
    }

    final now = DateTime.now();
    final lockedUntil =
        DateTime.fromMillisecondsSinceEpoch(lockedUntilMillis);
    final remaining = lockedUntil.difference(now);

    if (remaining <= Duration.zero) {
      await clearAttempts(normalizedEmail);
      return const SigninLockoutStatus(
        isLocked: false,
        remaining: Duration.zero,
        failedAttempts: 0,
      );
    }

    return SigninLockoutStatus(
      isLocked: true,
      remaining: remaining,
      failedAttempts: maxAttempts,
    );
  }

  Future<bool> registerInvalidAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    final status = await getStatus(normalizedEmail);
    if (status.isLocked) {
      return true;
    }

    final currentAttempts = prefs.getInt(_attemptsKey(normalizedEmail)) ?? 0;
    final nextAttempts = currentAttempts + 1;

    if (nextAttempts >= maxAttempts) {
      final lockedUntil = DateTime.now().add(lockDuration);
      await prefs.setInt(
        _lockedUntilKey(normalizedEmail),
        lockedUntil.millisecondsSinceEpoch,
      );
      await prefs.setInt(_attemptsKey(normalizedEmail), maxAttempts);
      return true;
    }

    await prefs.setInt(_attemptsKey(normalizedEmail), nextAttempts);
    return false;
  }

  Future<void> clearAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedEmail = _normalizeEmail(email);
    await prefs.remove(_attemptsKey(normalizedEmail));
    await prefs.remove(_lockedUntilKey(normalizedEmail));
  }
}

String formatLockoutRemaining(Duration remaining) {
  final totalSeconds = remaining.inSeconds;
  if (totalSeconds <= 0) {
    return '0m';
  }

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes == 0) {
    return '${seconds}s';
  }
  if (seconds == 0) {
    return '${minutes}m';
  }
  return '${minutes}m ${seconds}s';
}