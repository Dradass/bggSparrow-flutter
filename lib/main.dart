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
        //scaffoldBackgroundColor: Colors.deepPurple,
        secondaryHeaderColor: const Color.fromARGB(255, 43, 132, 190)),
    home: const NavigationExample(),
  ));
}

// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});

//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }

// class _MainScreenState extends State<MainScreen> {
//   late CameraController _controller;
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _controller = CameraController(cameras.first, ResolutionPreset.max);
//     _controller.initialize().then((_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {});
//     }).catchError((Object e) {
//       if (e is CameraException) {
//         switch (e.code) {
//           case 'CameraAccessDenied':
//             print("access was denied");
//             break;
//           default:
//             print(e.description);
//             break;
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(children: [
//         const Text('111'),
//         SizedBox(
//           height: 300,
//           child: CameraPreview(_controller),
//         ),
//         const Text("222"),
//       ]),
//     );
//   }
// }

// // A screen that allows users to take a picture using a given camera.
// class TakePictureScreen extends StatefulWidget {
//   const TakePictureScreen({
//     super.key,
//     required this.camera,
//   });

//   final CameraDescription camera;

//   @override
//   TakePictureScreenState createState() => TakePictureScreenState();
// }

// class TakePictureScreenState extends State<TakePictureScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();

//     // To display the current output from the Camera,
//     // create a CameraController.
//     _controller = CameraController(
//       // Get a specific camera from the list of available cameras.
//       widget.camera,
//       // Define the resolution to use.
//       ResolutionPreset.medium,
//     );

//     // Next, initialize the controller. This returns a Future.
//     _initializeControllerFuture = _controller.initialize();
//   }

//   @override
//   void dispose() {
//     // Dispose of the controller when the widget is disposed.
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Fill this out in the next steps.
//     return Container();
//   }
//}
