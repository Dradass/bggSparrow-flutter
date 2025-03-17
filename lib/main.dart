import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../navigation_bar.dart';
import '../pages/login_screen.dart';
import 'bggApi/bgg_api.dart';
import '../db/game_things_sql.dart';
import '../login_handler.dart';

// TODO
// 1. Debug mode for camera capture
// 2. No borders to buttons
// 3. Color picker
// 4. Icons and background

late List<CameraDescription> cameras;
const primaryTextColor = Color.fromARGB(255, 85, 92, 89);
bool backgroundLoading = false;
bool needLogin = true;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GameThingSQL.initTables();
  cameras = await availableCameras();
  needLogin = !await checkLoginFromStorage();
  if (!needLogin) {
    await LoginHandler().readLoginFromSecureStorage();
    await LoginHandler().readEncryptedPasswordFromSecureStorage();
  }

  runApp(MaterialApp(
    routes: {
      '/login': (context) => const LoginScreen(),
      '/navigation': (context) => const NavigationScreen(),
    },
    initialRoute: needLogin ? '/login' : '/navigation',
    theme: ThemeData(
        textTheme: const TextTheme()
            .apply(bodyColor: primaryTextColor, displayColor: Colors.blue),
        colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: primaryTextColor,
            onPrimary: Color.fromARGB(255, 183, 187, 187),
            secondary: Color.fromARGB(255, 110, 235, 173),
            onSecondary: primaryTextColor,
            error: Colors.red,
            onError: primaryTextColor,
            surface: Color.fromARGB(255, 247, 255, 249),
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
              side: BorderSide(color: Colors.black12)),
        )),
        sliderTheme:
            SliderThemeData(overlayShape: SliderComponentShape.noOverlay)),
  ));
}
