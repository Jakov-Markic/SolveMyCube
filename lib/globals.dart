import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

List<CameraDescription> globalCameras = [];

/// App-wide route observer, registered on [MaterialApp.navigatorObservers].
/// Lets any [RouteAware] widget know when it's been covered by a pushed
/// route (`didPushNext`) or uncovered again (`didPopNext`) - used by
/// [RubiksCube3D] to stop driving its GL surface while off-screen, since
/// only one three_js render surface should be actively rendering at a time.
final RouteObserver<ModalRoute<void>> globalRouteObserver =
    RouteObserver<ModalRoute<void>>();

class AppTheme {
  static ThemeData buildTheme({
    required Brightness brightness,
    required String fontFamily,
  }) {
    final colorScheme = brightness == Brightness.dark
        ? const ColorScheme.dark(
            primary: Color(0xFF4FC3F7),
            secondary: Color(0xFF80DEEA),
            surface: Color(0xFF10212B),
            onSurface: Color(0xFFEAF2F8),
            surfaceContainerHighest: Color(0xFF1F3341),
            outline: Color(0xFF5C7485),
            outlineVariant: Color(0xFF2F4553),
          )
        : const ColorScheme.light(
            primary: Color(0xFF006C84),
            secondary: Color(0xFF2D9CDB),
            surface: Color(0xFFF7FBFD),
            onSurface: Color(0xFF15252E),
            surfaceContainerHighest: Color(0xFFE5F3F8),
            outline: Color(0xFF8BA2AD),
            outlineVariant: Color(0xFFCFE6ED),
          );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}