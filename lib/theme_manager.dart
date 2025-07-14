import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _textColorParamName = 'textColor';
const String _surfaceColorParamName = 'surfaceColor';
const String _secondaryColorParamName = 'secondaryColor';

class ThemeManager extends ChangeNotifier {
  static late ThemeManager _instance;
  Color _textColor;
  Color _secondaryColor;
  Color _surfaceColor;

  ThemeManager(this._textColor, this._secondaryColor, this._surfaceColor);

  factory ThemeManager.instance() => _instance;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _instance = ThemeManager(
        _getColor(
            prefs, _textColorParamName, const Color.fromARGB(255, 85, 92, 89)),
        _getColor(prefs, _secondaryColorParamName,
            const Color.fromARGB(255, 110, 235, 173)),
        _getColor(prefs, _surfaceColorParamName,
            const Color.fromARGB(255, 247, 255, 249)));
  }

  static Color _getColor(
      SharedPreferences prefs, String key, Color defaultColor) {
    final savedColor = prefs.getInt(key);
    return savedColor != null ? Color(savedColor) : defaultColor;
  }

  Color get textColor => _textColor;
  Color get secondaryColor => _secondaryColor;
  Color get surfaceColor => _surfaceColor;

  set textColor(Color color) =>
      _updateColor(_textColorParamName, color, _textColor);
  set secondaryColor(Color color) =>
      _updateColor(_secondaryColorParamName, color, _secondaryColor);
  set surfaceColor(Color color) =>
      _updateColor(_surfaceColorParamName, color, _surfaceColor);

  void _updateColor(String key, Color newColor, Color currentColor) {
    if (newColor == currentColor) return;

    switch (key) {
      case _textColorParamName:
        _textColor = newColor;
        break;
      case _secondaryColorParamName:
        _secondaryColor = newColor;
        break;
      case _surfaceColorParamName:
        _surfaceColor = newColor;
        break;
    }

    _saveColor(key, newColor.value);
    notifyListeners();
  }

  Future<void> _saveColor(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> resetColors() async {
    textColor = const Color.fromARGB(255, 85, 92, 89);
    secondaryColor = const Color.fromARGB(255, 110, 235, 173);
    surfaceColor = const Color.fromARGB(255, 247, 255, 249);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_textColorParamName);
    await prefs.remove(_secondaryColorParamName);
    await prefs.remove(_surfaceColorParamName);
  }
}
