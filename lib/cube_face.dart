import 'package:flutter/material.dart';

enum Face { F, R, U, B, L, D }

extension FaceX on Face {
  String get label => name;

  Color get defaultColor => kFaceColors[this]!;
}

/// Default sticker color
const Map<Face, Color> kFaceColors = {
  Face.F: Colors.red,
  Face.R: Colors.blue,
  Face.U: Colors.white,
  Face.B: Colors.orange,
  Face.L: Colors.green,
  Face.D: Colors.yellow,
};

/// List of face colors from enum
final List<Color> kFaceColorList =
    Face.values.map((f) => kFaceColors[f]!).toList(growable: false);
