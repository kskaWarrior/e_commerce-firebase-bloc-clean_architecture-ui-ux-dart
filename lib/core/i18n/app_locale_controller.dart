import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale state, shared by the shopper (mobile + web) and admin
/// entrypoints. The selection persists across sessions; the default follows
/// the device/browser language (Portuguese speakers get pt-BR out of the
/// box, everyone else English).
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  static const String _storageKey = 'app_locale_v1';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('pt', 'BR'),
  ];

  Locale _locale = _systemDefault();

  Locale get locale => _locale;

  static Locale _systemDefault() {
    final systemLanguage =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return systemLanguage == 'pt'
        ? const Locale('pt', 'BR')
        : const Locale('en');
  }

  /// Loads the persisted choice (no-op when the user never picked one).
  Future<void> restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored == null || stored.isEmpty) {
        return;
      }
      final restored = stored == 'pt_BR'
          ? const Locale('pt', 'BR')
          : const Locale('en');
      if (restored != _locale) {
        _locale = restored;
        notifyListeners();
      }
    } catch (_) {
      // Locale restore must never block app startup.
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        locale.languageCode.toLowerCase() == 'pt' ? 'pt_BR' : 'en',
      );
    } catch (_) {
      // Persistence failures should not break the in-session switch.
    }
  }
}
