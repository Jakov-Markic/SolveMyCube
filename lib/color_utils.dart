import 'package:flutter/material.dart';

class ColorUtils {
  // Compare colors with tolerance for small variations
  static bool areColorsEqual(Color a, Color b, {double tolerance = 0.05}) {
    return (a.r - b.r).abs() <= tolerance &&
           (a.g - b.g).abs() <= tolerance &&
           (a.b - b.b).abs() <= tolerance &&
           (a.a - b.a).abs() <= tolerance;
  }

  // Get a unique string representation for signature generation
  static String colorToString(Color color) {
    // Round to nearest integer to avoid floating point issues
    int r = color.r.round();
    int g = color.g.round();
    int b = color.b.round();
    int a = color.a.round();
    return '$r,$g,$b,$a';
  }

  // Get a simple color code (0-5) for PLL signature
  static int getColorCode(Color color, List<Color> centerColors) {
    for (int i = 0; i < centerColors.length; i++) {
      if (areColorsEqual(color, centerColors[i])) {
        return i;
      }
    }
    return -1; // Should never happen
  }
}