import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';

  static const List<String> themes = [light, dark, system];

  static String get defaultTheme => light;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(AppColors.lightPrimary),
    primaryColorDark: const Color(AppColors.lightPrimaryVariant),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(AppColors.lightPrimary),
      onPrimary: Color(AppColors.lightOnPrimary),
      secondary: Color(AppColors.lightSecondary),
      onSecondary: Color(AppColors.lightOnSecondary),
      surface: Color(AppColors.lightSurface),
      onSurface: Color(AppColors.lightOnSurface),
      error: Color(AppColors.lightError),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(AppColors.lightBackground),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(AppColors.lightPrimary),
      foregroundColor: Color(AppColors.lightOnPrimary),
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(AppColors.darkPrimary),
    primaryColorDark: const Color(AppColors.darkPrimaryVariant),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(AppColors.darkPrimary),
      onPrimary: Color(AppColors.darkOnPrimary),
      secondary: Color(AppColors.darkSecondary),
      onSecondary: Color(AppColors.darkOnSecondary),
      surface: Color(AppColors.darkSurface),
      onSurface: Color(AppColors.darkOnSurface),
      error: Color(AppColors.darkError),
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(AppColors.darkBackground),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(AppColors.darkPrimary),
      foregroundColor: Color(AppColors.darkOnPrimary),
      elevation: 0,
    ),
  );

  static ThemeData getTheme(String theme) {
    switch (theme) {
      case dark:
        return darkTheme;
      case light:
        return lightTheme;
      default:
        return lightTheme;
    }
  }
}