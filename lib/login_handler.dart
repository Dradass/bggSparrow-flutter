import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class LoginHandler {
  static final LoginHandler _singleton = LoginHandler._internal();

  factory LoginHandler() {
    return _singleton;
  }

  LoginHandler._internal();

  String login = "";
  String encryptedPassword = "";
  String encryptionKey = getRandomString(15);

  Future<void> readEncryptedPasswordFromSecureStorage() async {
    encryptedPassword =
        ((await const FlutterSecureStorage().read(key: "password"))!);
    // TODO Encrypt password
    // final encrypter = EncryptionHelper(encryptionKey);
    // encryptedPassword = encrypter
    //     .encrypt((await const FlutterSecureStorage().read(key: "password"))!);
  }

  String getDecryptedPassword() {
    // final encrypter = EncryptionHelper(encryptionKey);
    // return encrypter.decrypt(encryptedPassword);
    return encryptedPassword;
  }

  Future<void> readLoginFromSecureStorage() async {
    login = ((await const FlutterSecureStorage().read(key: "username"))!);
  }
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

class EncryptionHelper {
  final Key key;
  final IV iv;

  EncryptionHelper(String secret)
      : key = Key.fromUtf8(secret.padRight(32, '0').substring(0, 32)),
        iv = IV.fromLength(16);

  String encrypt(String input) {
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(input, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String input) {
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt64(input, iv: iv);
    return decrypted;
  }
}
