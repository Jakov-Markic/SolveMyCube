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

/// Colors actually sampled from real cube photos (two physical cubes, camera-
/// captured under normal indoor lighting - see the CVAT-labeled front-face
/// quads in `shared_datasets/pose_dataset_combined_cvat_8pt`), used only as
/// [FaceColorExtractor]'s classification reference before any per-session
/// calibration exists for an identity. [kFaceColors] stays the idealized
/// Material palette used everywhere a color is *displayed or stored* (manual
/// fill's picker, the cube widget, a captured sticker's saved value) - mixing
/// the two up would make manually-picked colors look inconsistent with the
/// auto-fill result. This palette exists because matching camera pixels
/// against [kFaceColors] directly misclassifies real orange stickers as red
/// with 90%+ confidence: Material's `Colors.orange` (0xFFFF9800) is a pure,
/// zero-blue orange, while a real orange sticker photographs far more
/// desaturated and blue-shifted, landing hue-wise right next to red.
const Map<Face, Color> kMeasuredReferenceColors = {
  Face.F: Color(0xFFCB3442), // red   - measured ~(203, 52, 66)
  Face.R: Color(0xFF025ACF), // blue  - measured ~(2, 90, 207)
  Face.U: Color(0xFFD8DCEC), // white - measured ~(216, 220, 236), slight blue cast
  Face.B: Color(0xFFDE5C32), // orange - measured ~(222, 92, 50)
  Face.L: Color(0xFF14A928), // green - measured ~(20, 169, 40)
  Face.D: Color(0xFFD5C424), // yellow - measured ~(213, 196, 36)
};
