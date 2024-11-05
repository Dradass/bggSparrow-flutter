import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:requests/requests.dart';
import '../navigation_bar.dart';
import '../db/system_table.dart';
import '../models/system_parameters.dart';
import '../db/game_things_sql.dart';
import '../bggApi/bggApi.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final userNameParamName = "username";
  final passwordParamName = "password";

  @override
  void dispose() {
    loginTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextField(
          controller: loginTextController,
          decoration: InputDecoration(
            labelText: 'Login',
            filled: true,
          ),
        ),
        TextField(
            controller: passwordTextController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              //filled: true,
            )),
        ElevatedButton(
            onPressed: () => {
                  checkLoginByRequest(
                          loginTextController.text, passwordTextController.text)
                      .then((isLoginCorrent) => {
                            if (isLoginCorrent)
                              {
                                Navigator.pushNamed(context, '/navigation'),
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Welcome!'))),
                                UpdateLoginPassword(loginTextController.text,
                                    passwordTextController.text, context)
                              }
                            else
                              {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Login or password is incorrect')))
                              }
                          })
                },
            child: Text("Log in"))
      ]),
    );
  }

  void UpdateLoginPassword(
      String username, String password, BuildContext context) {
    final storage = FlutterSecureStorage();
    storage.read(key: userNameParamName).then((usernameStorage) {
      if (usernameStorage == null) {
        print("no param");
        storage.write(key: userNameParamName, value: username);
      } else {
        storage.write(key: userNameParamName, value: username);
      }
    });

    storage.read(key: passwordParamName).then((passwordParam) {
      if (passwordParam == null) {
        print("no param");
        storage.write(key: passwordParamName, value: password);
      } else {
        storage.write(key: passwordParamName, value: password);
      }
    });
    // При запуске приложения проверять данные из БД. Отправить запрос, т.к. данные на сервер могли поменять
  }
}
