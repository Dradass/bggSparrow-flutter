import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:ui' as ui;

class S with ChangeNotifier {
  static final ValueNotifier<Locale> _localeNotifier =
      ValueNotifier(S.getDefaultLocale());

  static const List<Map<String, dynamic>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
  ];

  static void setLocale(Locale newLocale) {
    if (newLocale != _localeNotifier.value) {
      _localeNotifier.value = newLocale;
    }
  }

  static Locale getDefaultLocale() {
    var defaultLocale =
        Locale(ui.PlatformDispatcher.instance.locale.languageCode);
    if (supportedLanguages
        .any((lang) => lang['code'] == defaultLocale.languageCode)) {
      return defaultLocale;
    } else {
      return const Locale('en');
    }
  }

  static const localizationDelegates = <LocalizationsDelegate>[
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    AppLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context);

  static Locale get currentLocale => _localeNotifier.value;

  static ValueNotifier<Locale> get notifier => _localeNotifier;
}
