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

late List<CameraDescription> cameras;
bool backgroundLoading = false;
bool needLogin = true;
const primaryTextColor = Color.fromARGB(255, 85, 92, 89);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.initialize();

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
                  textTheme: const TextTheme().apply(
                    bodyColor: primaryTextColor,
                    displayColor: Colors.blue,
                  ),
                  colorScheme: ColorScheme(
                      brightness: Brightness.light,
                      primary: themeManager.textColor,
                      onPrimary: Color.fromARGB(255, 183, 187, 187),
                      secondary: themeManager.secondaryColor,
                      onSecondary: primaryTextColor,
                      error: Colors.red,
                      onError: primaryTextColor,
                      surface: themeManager.surfaceColor,
                      onSurface: primaryTextColor),
                  secondaryHeaderColor: const Color.fromARGB(255, 43, 132, 190),
                  chipTheme: ChipThemeData(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black12),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(Radius.zero),
                        side: BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  sliderTheme: SliderThemeData(
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
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
