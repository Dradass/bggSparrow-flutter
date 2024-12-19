import 'package:flutter/material.dart';
import 'package:flutter_application_1/task_checker.dart';
import '../bggApi/bggApi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const userNameParamName = "username";
const passwordParamName = "password";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Divider(),
        TextField(
          controller: loginTextController,
          decoration: const InputDecoration(
            labelText: 'Login',
          ),
        ),
        TextField(
            controller: passwordTextController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            )),
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.1,
            child: LoginButton(loginTextController, passwordTextController))
      ]),
    );
  }
}

void updateLoginPassword(
    String username, String password, BuildContext context) {
  const storage = FlutterSecureStorage();
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
}

class LoginButton extends StatefulWidget {
  LoginButton(this.loginTextController, this.paswordTextController,
      {super.key});

  TextEditingController loginTextController;
  TextEditingController paswordTextController;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () => {
              checkLoginByRequest(widget.loginTextController.text,
                      widget.paswordTextController.text)
                  .then((isLoginCorrent) => {
                        if (isLoginCorrent)
                          {
                            TaskChecker().needCancel = false,
                            Navigator.pushNamed(context, '/navigation'),
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Welcome!'))),
                            updateLoginPassword(widget.loginTextController.text,
                                widget.paswordTextController.text, context)
                          }
                        else
                          {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Login or password is incorrect')))
                          }
                      })
            },
        child: const Text("Log in"));
  }
}
