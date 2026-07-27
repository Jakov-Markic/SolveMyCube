/*Comment what to do in future 
1. Make title
2. Make bottom navigation (main, timer, setting)
- main will include grid view of all cubes that will be widgets that link to their respective page
- timer will just be a timer used for solving
- setting will be list of options: theme change, language option, constumer service, terms of service, etc.
3. Make custom widget and make grid view of it
4. (Optional) Make background of widget 3d

*/

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/library.dart' as page;
import 'globals.dart';
import 'settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();

  globalCameras = await availableCameras();

  final prefs = await SharedPreferences.getInstance();
  final settingsStore = SettingsStore(prefs);
  final initialSettings = settingsStore.loadSettings();

  runApp(MainApp(settingsStore: settingsStore, initialSettings: initialSettings));
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.settingsStore,
    required this.initialSettings,
  });

  final SettingsStore settingsStore;
  final AppSettings initialSettings;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late ThemeMode _themeMode;
  late String _selectedFontFamily;
  late String _selectedAlgorithm;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialSettings.themeMode;
    _selectedFontFamily = widget.initialSettings.fontFamily;
    _selectedAlgorithm = widget.initialSettings.algorithm;
  }

  Future<void> _handleThemeModeChanged(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    await widget.settingsStore.saveThemeMode(mode);
  }

  Future<void> _handleFontFamilyChanged(String fontFamily) async {
    setState(() {
      _selectedFontFamily = fontFamily;
    });
    await widget.settingsStore.saveFontFamily(fontFamily);
  }

  Future<void> _handleAlgorithmChanged(String algorithm) async {
    setState(() {
      _selectedAlgorithm = algorithm;
    });
    await widget.settingsStore.saveAlgorithm(algorithm);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.buildTheme(
        brightness: Brightness.light,
        fontFamily: _selectedFontFamily,
      ),
      darkTheme: AppTheme.buildTheme(
        brightness: Brightness.dark,
        fontFamily: _selectedFontFamily,
      ),
      home: MainScreen(
        themeMode: _themeMode,
        selectedFontFamily: _selectedFontFamily,
        selectedAlgorithm: _selectedAlgorithm,
        onThemeModeChanged: _handleThemeModeChanged,
        onFontFamilyChanged: _handleFontFamilyChanged,
        onAlgorithmChanged: _handleAlgorithmChanged,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String selectedFontFamily;
  final String selectedAlgorithm;
  final Future<void> Function(ThemeMode) onThemeModeChanged;
  final Future<void> Function(String) onFontFamilyChanged;
  final Future<void> Function(String) onAlgorithmChanged;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.selectedFontFamily,
    required this.selectedAlgorithm,
    required this.onThemeModeChanged,
    required this.onFontFamilyChanged,
    required this.onAlgorithmChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const page.MainPage(),
      const page.PageTimer(),
      page.PageSettings(
        themeMode: widget.themeMode,
        selectedFontFamily: widget.selectedFontFamily,
        selectedAlgorithm: widget.selectedAlgorithm,
        onThemeModeChanged: widget.onThemeModeChanged,
        onFontFamilyChanged: widget.onFontFamilyChanged,
        onAlgorithmChanged: widget.onAlgorithmChanged,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode ||
        oldWidget.selectedFontFamily != widget.selectedFontFamily ||
        oldWidget.selectedAlgorithm != widget.selectedAlgorithm) {
      _pages[2] = page.PageSettings(
        themeMode: widget.themeMode,
        selectedFontFamily: widget.selectedFontFamily,
        selectedAlgorithm: widget.selectedAlgorithm,
        onThemeModeChanged: widget.onThemeModeChanged,
        onFontFamilyChanged: widget.onFontFamilyChanged,
        onAlgorithmChanged: widget.onAlgorithmChanged,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.center,
          child: Text('Solve My Cube'),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}
