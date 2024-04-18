import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../navigation_bar.dart';

late List<CameraDescription> cameras;
const primaryTextColor = Color.fromARGB(255, 85, 92, 89);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(MaterialApp(
    theme: ThemeData(
        //primaryColor: Color.fromARGB(255, 219, 202, 124),
        textTheme: const TextTheme()
            .apply(bodyColor: primaryTextColor, displayColor: Colors.blue),
        colorScheme: const ColorScheme(
            brightness: Brightness.light,
            background: Color.fromARGB(255, 218, 245, 234),
            onBackground: primaryTextColor,
            primary: primaryTextColor,
            onPrimary: Color.fromARGB(255, 183, 187, 187),
            secondary: Color.fromARGB(255, 46, 207, 127),
            onSecondary: primaryTextColor,
            error: Colors.red,
            onError: primaryTextColor,
            surface: Color.fromARGB(255, 148, 226, 181),
            onSurface: primaryTextColor),
        secondaryHeaderColor: const Color.fromARGB(255, 43, 132, 190),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Colors.black12)))),
        )),
    home: const NavigationExample(),
  ));
}
