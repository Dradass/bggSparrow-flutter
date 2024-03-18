// import 'package:flutter/material.dart';

// class CameraDialog extends StatelessWidget {
//   const CameraDialog({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return const Placeholder();
//   }
// }

// AlertDialog(
//                               title: Text('Take photo'),
//                               content: Column(children: [
//                                 Text("$recognizedImage"),
//                                 Container(
//                                   height: 300,
//                                   child: CameraPreview(_controller),
//                                 ),
//                                 ElevatedButton(
//                                     onPressed: () async {
//                                       setState(() {
//                                         recognizedImage = "Getting image from";
//                                       });
//                                       Navigator.of(context, rootNavigator: true)
//                                           .pop();
//                                       setState(() {
//                                         recognizedImage = "AfterPop";
//                                       });
//                                       final gameId = await TakePhoto();
//                                       setState(() {
//                                         recognizedImage = "Taken Photo";
//                                       });

//                                       setState(() {
//                                         recognizedImage = gameId.toString();
//                                       });
//                                     },
//                                     child: Text('Press me'))
//                               ]),
//                             );