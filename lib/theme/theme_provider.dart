import 'package:flutter/material.dart';

/// بيتحكم في وضع الثيم: فاتح / غامق / حسب إعدادات الموبايل (System)
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // البداية بتتبع إعدادات الموبايل

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
