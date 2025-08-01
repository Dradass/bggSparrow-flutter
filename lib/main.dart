import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../navigation_bar.dart';
import '../pages/login_screen.dart';
import 'bggApi/bgg_api.dart';
import '../db/game_things_sql.dart';
import '../login_handler.dart';
import '../s.dart';
import 'theme_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;
bool backgroundLoading = false;
bool needLogin = true;
const primaryTextColor = Color.fromARGB(255, 85, 92, 89);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

  final prefs = await SharedPreferences.getInstance();
  String? defaultLanguage = prefs.getString('default_language');
  if (defaultLanguage != null) {
    S.setLocale(Locale(defaultLanguage));
  }

  GameThingSQL.initTables();
  cameras = await availableCameras();
  needLogin = !await checkLoginFromStorage();
  if (!needLogin) {
    await LoginHandler().readLoginFromSecureStorage();
    await LoginHandler().readEncryptedPasswordFromSecureStorage();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ThemeManager.instance(),
      child: ValueListenableBuilder<Locale>(
        valueListenable: S.notifier,
        builder: (context, locale, child) {
          return Consumer<ThemeManager>(
            builder: (context, themeManager, child) {
              return MaterialApp(
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/navigation': (context) => const NavigationScreen(),
                },
                initialRoute: needLogin ? '/login' : '/navigation',
                theme: ThemeData(
                  textTheme: TextTheme(
                    bodyLarge: TextStyle(
                        color: themeManager.textColor), // Основной текст
                    bodyMedium: TextStyle(color: themeManager.textColor),
                    bodySmall: TextStyle(color: themeManager.textColor),
                    displayLarge: TextStyle(color: themeManager.textColor),
                    displayMedium: TextStyle(color: themeManager.textColor),
                    displaySmall: TextStyle(color: themeManager.textColor),
                    headlineLarge: TextStyle(color: themeManager.textColor),
                    headlineMedium: TextStyle(color: themeManager.textColor),
                    headlineSmall: TextStyle(color: themeManager.textColor),
                    titleLarge: TextStyle(
                        color: themeManager.textColor), // Заголовки AppBar
                    titleMedium: TextStyle(color: themeManager.textColor),
                    titleSmall: TextStyle(color: themeManager.textColor),
                    labelLarge:
                        TextStyle(color: themeManager.textColor), // Кнопки
                    labelMedium: TextStyle(color: themeManager.textColor),
                    labelSmall: TextStyle(color: themeManager.textColor),
                  ).apply(
                    bodyColor: themeManager.textColor,
                    displayColor: themeManager.textColor,
                  ),
                  primaryTextTheme:
                      const TextTheme().apply(bodyColor: Colors.blue),
                  colorScheme: ColorScheme(
                      brightness: Brightness.light,
                      primary: themeManager.textColor,
                      onPrimary: const Color.fromARGB(255, 183, 187, 187),
                      secondary: themeManager.secondaryColor,
                      onSecondary: primaryTextColor,
                      error: Colors.red,
                      onError: primaryTextColor,
                      surface: themeManager.surfaceColor,
                      onSurface: primaryTextColor),
                  secondaryHeaderColor: const Color.fromARGB(255, 43, 132, 190),
                  chipTheme: const ChipThemeData(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black12),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.zero),
                        side: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  checkboxTheme: CheckboxThemeData(
                      side: BorderSide(color: themeManager.textColor)),
                  navigationBarTheme: NavigationBarThemeData(
                      labelTextStyle: WidgetStateProperty.all(TextStyle(
                    color: themeManager.textColor,
                  ))),
                  sliderTheme: SliderThemeData(
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                      helperStyle: TextStyle(color: themeManager.textColor),
                      hintStyle: TextStyle(color: themeManager.textColor),
                      labelStyle: TextStyle(color: themeManager.textColor)),
                ),
                supportedLocales: S.supportedLanguages
                    .map((toElement) => Locale(toElement['code'])),
                locale: locale,
                localizationsDelegates: S.localizationDelegates,
              );
            },
          );
        },
      ),
    );
  }
}
