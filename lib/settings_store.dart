import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String fontFamily;
  final String algorithm;

  const AppSettings({
    required this.themeMode,
    required this.fontFamily,
    required this.algorithm,
  });
}

class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _themeKey = 'theme_mode';
  static const String _fontKey = 'font_family';
  static const String _algorithmKey = 'algorithm';

  AppSettings loadSettings() {
    final themeName = _prefs.getString(_themeKey);
    final fontFamily = _prefs.getString(_fontKey) ?? 'Roboto';
    final algorithm = _prefs.getString(_algorithmKey) ?? 'CFOP';

    return AppSettings(
      themeMode: themeName == 'dark' ? ThemeMode.dark : ThemeMode.light,
      fontFamily: fontFamily,
      algorithm: algorithm,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> saveFontFamily(String fontFamily) async {
    await _prefs.setString(_fontKey, fontFamily);
  }

  Future<void> saveAlgorithm(String algorithm) async {
    await _prefs.setString(_algorithmKey, algorithm);
  }
}
