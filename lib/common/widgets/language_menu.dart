import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_locale_controller.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:flutter/material.dart';

const _languages = [
  (locale: Locale('en'), label: 'English'),
  (locale: Locale('pt', 'BR'), label: 'Português (Brasil)'),
];

bool _isSelected(Locale option, Locale current) =>
    option.languageCode == current.languageCode;

/// Compact globe popup used in app bars / headers / sidebars.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.iconColor, this.iconSize = 22});

  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final current = AppLocaleController.instance.locale;

    return PopupMenuButton<Locale>(
      tooltip: S.of(context).language,
      icon: Icon(Icons.language, size: iconSize, color: iconColor),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: AppLocaleController.instance.setLocale,
      itemBuilder: (context) => [
        for (final language in _languages)
          PopupMenuItem<Locale>(
            value: language.locale,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: _isSelected(language.locale, current)
                      ? const Icon(Icons.check, size: 17)
                      : null,
                ),
                Text(
                  language.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _isSelected(language.locale, current)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Radio-list dialog used from the mobile drawer / admin sidebar.
Future<void> showLanguagePicker(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final current = AppLocaleController.instance.locale;
      final selected = _languages
          .firstWhere(
            (language) => _isSelected(language.locale, current),
            orElse: () => _languages.first,
          )
          .locale;
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(S.of(dialogContext).language),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final language in _languages)
              RadioListTile<Locale>(
                value: language.locale,
                groupValue: selected,
                title: Text(language.label),
                onChanged: (_) {
                  AppLocaleController.instance.setLocale(language.locale);
                  Navigator.pop(dialogContext);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(dialogContext).cancel),
          ),
        ],
      );
    },
  );
}
