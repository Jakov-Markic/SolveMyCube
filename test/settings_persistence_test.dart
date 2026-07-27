import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solve_my_cube/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsStore', () {
    test('loads default values when no preferences are saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SettingsStore(prefs);

      final settings = store.loadSettings();

      expect(settings.themeMode, ThemeMode.light);
      expect(settings.fontFamily, 'Roboto');
      expect(settings.algorithm, 'CFOP');
    });

    test('saves and reloads theme, font, and algorithm values', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SettingsStore(prefs);

      await store.saveThemeMode(ThemeMode.dark);
      await store.saveFontFamily('Courier');
      await store.saveAlgorithm('Kociemba');

      final settings = store.loadSettings();

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.fontFamily, 'Courier');
      expect(settings.algorithm, 'Kociemba');
    });
  });
}
