import 'package:flutter/material.dart';
import 'package:flutter_application_1/login_handler.dart';
import 'package:flutter_application_1/task_checker.dart';
import '../bggApi/bgg_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const userNameParamName = "username";
const passwordParamName = "password";
String? errorLoginText;
String? errorPasswordText;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final loginTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  @override
  void dispose() {
    loginTextController.dispose();
    passwordTextController.dispose();
    super.dispose();
  }

  void checkLoginAndPassword() {
    if (loginTextController.text.isEmpty) {
      setState(() {
        errorLoginText = 'Enter login';
        errorPasswordText = null;
      });
      return;
    }
    if (passwordTextController.text.isEmpty) {
      setState(() {
        errorLoginText = null;
        errorPasswordText = 'Enter password';
      });
      return;
    }
    checkLoginByRequest(loginTextController.text, passwordTextController.text)
        .then((isLoginCorrent) => {
              if (isLoginCorrent)
                {
                  setState(() {
                    errorLoginText = null;
                    errorPasswordText = null;
                  }),
                  TaskChecker().needCancel = false,
                  Navigator.pushNamed(context, '/navigation'),
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Welcome!'))),
                  updateLoginPassword(loginTextController.text,
                      passwordTextController.text, context)
                }
              else
                {
                  setState(() {
                    errorPasswordText = 'Login or password is incorrect';
                  })
                }
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Divider(),
        TextField(
          controller: loginTextController,
          decoration: InputDecoration(
            labelText: 'Login',
            errorText: errorLoginText,
          ),
        ),
        TextField(
            controller: passwordTextController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: errorPasswordText,
            )),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: ElevatedButton(
                onPressed: checkLoginAndPassword,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.secondary),
                ),
                child: const Text("Log in")))
      ]),
    );
  }
}

void updateLoginPassword(
    String username, String password, BuildContext context) {
  const storage = FlutterSecureStorage();

  storage.read(key: userNameParamName).then((usernameStorage) {
    if (usernameStorage == null) {
      storage.write(key: userNameParamName, value: username);
    } else {
      storage.write(key: userNameParamName, value: username);
    }
  });

  LoginHandler().login = username;

  storage.read(key: passwordParamName).then((passwordParam) {
    if (passwordParam == null) {
      storage.write(key: passwordParamName, value: password);
    } else {
      storage.write(key: passwordParamName, value: password);
    }
  });

  LoginHandler().encryptedPassword = password;
}
