import 'package:flutter/material.dart';
import 'package:downtown/core/services/app_preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final savedTheme = await AppPreferencesService.getThemeMode();
    if (savedTheme != null) {
      _themeMode = savedTheme;
      notifyListeners();
    }
  }
  
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await AppPreferencesService.saveThemeMode(_themeMode);
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await AppPreferencesService.saveThemeMode(_themeMode);
      notifyListeners();
    }
  }
}
