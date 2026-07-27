import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_locale_controller.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:flutter/material.dart';

const _languages = [
  (locale: Locale('en'), label: 'English', short: 'EN'),
  (locale: Locale('pt', 'BR'), label: 'Português (Brasil)', short: 'PT-BR'),
];

bool _isSelected(Locale option, Locale current) =>
    option.languageCode == current.languageCode;

/// Globe popup used in app bars / headers / sidebars. With [showLabel] it
/// renders as an explicit outlined pill showing the current language code
/// instead of a bare icon.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({
    super.key,
    this.iconColor,
    this.iconSize = 22,
    this.showLabel = false,
  });

  final Color? iconColor;
  final double iconSize;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final current = AppLocaleController.instance.locale;
    final currentShort = _languages
        .firstWhere(
          (language) => _isSelected(language.locale, current),
          orElse: () => _languages.first,
        )
        .short;

    final items = [
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
    ];

    if (!showLabel) {
      return PopupMenuButton<Locale>(
        tooltip: S.of(context).language,
        icon: Icon(Icons.language, size: iconSize, color: iconColor),
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: AppLocaleController.instance.setLocale,
        itemBuilder: (context) => items,
      );
    }

    final color = iconColor ?? context.brand.iconStrong;
    return PopupMenuButton<Locale>(
      tooltip: S.of(context).language,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: AppLocaleController.instance.setLocale,
      itemBuilder: (context) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              currentShort,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

/// Fully explicit two-option segmented pill: both languages always visible,
/// the active one highlighted. Used where the selector must be obvious
/// (e.g. the web sign-in card).
class LanguageSelectorPill extends StatelessWidget {
  const LanguageSelectorPill({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) {
        final current = AppLocaleController.instance.locale;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: brand.surfaceBright.withOpacity(0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: brand.iconStrong.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final language in _languages)
                _PillSegment(
                  label: language.short,
                  selected: _isSelected(language.locale, current),
                  onTap: () => AppLocaleController.instance
                      .setLocale(language.locale),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? brand.iconStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: selected ? brand.textInverse : brand.textPrimary,
            ),
          ),
        ),
      ),
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
