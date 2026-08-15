import 'package:flutter/material.dart';

/// The 6 faces of a Rubik's cube, in the fixed order used throughout the app
/// for face-indexed grids (matches [RubiksCube.grid]'s first dimension).
enum Face { F, R, U, B, L, D }

extension FaceX on Face {
  /// Single-letter cube notation label (matches the enum's own name).
  String get label => name;

  /// The sticker color this face has when the cube is in its solved state.
  Color get defaultColor => kFaceColors[this]!;
}

/// Canonical sticker color for each face when the cube is solved.
const Map<Face, Color> kFaceColors = {
  Face.F: Colors.red,
  Face.R: Colors.blue,
  Face.U: Colors.white,
  Face.B: Colors.orange,
  Face.L: Colors.green,
  Face.D: Colors.yellow,
};

/// [kFaceColors] values in [Face.values] order - handy where a plain list of
/// the 6 valid sticker colors is more convenient than the map (e.g. a color
/// picker, or `List.indexOf` against a known palette).
final List<Color> kFaceColorList =
    Face.values.map((f) => kFaceColors[f]!).toList(growable: false);
