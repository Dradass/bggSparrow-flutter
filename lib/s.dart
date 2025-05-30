import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class S with ChangeNotifier {
  static final ValueNotifier<Locale> _localeNotifier =
      ValueNotifier(const Locale('en'));

  static dynamic locale = Locale('ru');

  static const List<Map<String, dynamic>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
  ];

  static void setLocale(Locale newLocale) {
    if (newLocale != _localeNotifier.value) {
      _localeNotifier.value = newLocale;
    }
  }

  static const supportedLocales = [Locale('en'), Locale('ru')];

  static const localizationDelegates = <LocalizationsDelegate>[
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    AppLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context);

  static Locale get currentLocale => _localeNotifier.value;

  static void toggleLocale() {
    _localeNotifier.value = _localeNotifier.value.languageCode == 'en'
        ? const Locale('ru')
        : const Locale('en');
  }

  static ValueNotifier<Locale> get notifier => _localeNotifier;
}
