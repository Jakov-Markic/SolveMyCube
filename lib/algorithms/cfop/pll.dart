import 'package:flutter/material.dart';
import '../rubik_cube.dart';
import '../../color_utils.dart';

final Map<String, String> standardPLLAlgorithms = {
  // --- A Permutations ---
  "002310121233": "R' F R' B2 R F' R' B2 R2", // Aa Perm
  "001212320133": "R2 B2 R F R' B2 R F' R", // Ab Perm

  // --- E Permutation ---
  "103012321230": "R' U L' D2 L U' R L' U R' D2 R U' L", // E Perm

  // --- F Permutation ---
  "021210102333": "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R", // F Perm

  // --- G Permutations ---
  "031200211323": "R2 U R' U R' U' R U' R2 D U' R U' R' D'", // Ga Perm
  "003122130103": "R' U' R U D' R2 U R' U R U' R U' R2 D", // Gb Perm
  "210120132033": "R2 U' R U' R U R' U R2 D' U R' U R D'", // Gc Perm
  "300102311123": "R U R' U' D R2 U' R U' R' U R' U R2 D'", // Gd Perm

  // --- H Permutation ---
  "020131202313": "M2 U M2 U2 M2 U M2", // H Perm

  // --- J Permutations ---
  "001220112333": "R' U2 R U R' U2 L U' R U L'", // Ja Perm
  "011200122333": "R U R' F' R U R' U' R' F R2 U' R' U'", // Jb Perm

  // --- N Permutations ---
  "200133022311": "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'", // Na Perm
  "113002331220": "R' U L' U2 R U' L R' U L' U2 R U' L", // Nb Perm

  // --- R Permutations ---
  "330103021212": "R U R' F' R U2 R' U2 R' F R U R U2 R'", // Ra Perm
  "010102321233": "R' U2 R U2 R' F R U R' U' R' F' R2 U'", // Rb Perm

  // --- T Permutation ---
  "001230122313": "R U R' U' R' F R2 U' R' U' R U R' F'", // T Perm

  // --- U Permutations ---
  "010131222303": "R U' R U R U R U' R' U' R2", // Ua Perm
  "030101222313": "R2 U R U R' U' R' U' R' U R'", // Ub Perm

  // --- V Permutation ---
  "002321210133": "R' U R' U' B' R' B2 U' B' U B' R B R", // V Perm

  // --- W Permutation ---
  "231201311031": "R' U R' U' R' F R2 U' R' U R F' R", // W Perm

  // --- Z Permutation ---
  "010101232323": "M2 U M2 U M' U2 M2 U2 M' U2", // Z Perm
};

String solvePLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();
  final topColor = cube.getCenterColor(Face.U);
  final seenSignatures = <String>{};

  for (int iteration = 0; iteration < 24; iteration++) {
    final signature = getPLLSignature(cube);

    if (signature == "000111222333" || isPLLResolved(cube, topColor)) {
      int aufAttempts = 0;
      while (!ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cube.getCenterColor(Face.F))) {
        cube.executeSequence("U");
        steps.write("U ");
        aufAttempts++;
        if (aufAttempts >= 4) throw StateError("Final AUF alignment failed.");
      }
      return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    }

    if (standardPLLAlgorithms.containsKey(signature)) {
      final algorithm = standardPLLAlgorithms[signature]!;
      cube.executeSequence(algorithm);
      steps.write("$algorithm ");
      seenSignatures.clear();
      continue;
    }

    if (seenSignatures.contains(signature)) {
      cube.rotateCubeY();
      steps.write("y ");
      seenSignatures.clear();
    } else {
      seenSignatures.add(signature);
    }

    cube.executeSequence("U");
    steps.write("U ");
  }

  final signature = getPLLSignature(cube);
  final topFaceIsSolved = isPLLResolved(cube, topColor);

  throw StateError(
    'PLL could not find a matching case. Signature=$signature, topFaceSolved=$topFaceIsSolved. '
    'This usually means the cube did not reach a valid PLL state before this phase.',
  );
}

String getPLLSignature(RubiksCube cube) {
  StringBuffer sig = StringBuffer();

  Color colorF = cube.getCenterColor(Face.F);
  Color colorR = cube.getCenterColor(Face.R);
  Color colorB = cube.getCenterColor(Face.B);
  Color colorL = cube.getCenterColor(Face.L);

  String getColorCode(Color color) {
    if (ColorUtils.areColorsEqual(color, colorF)) return "0";
    if (ColorUtils.areColorsEqual(color, colorR)) return "1";
    if (ColorUtils.areColorsEqual(color, colorB)) return "2";
    if (ColorUtils.areColorsEqual(color, colorL)) return "3";
    return "?";
  }

  final sideFaces = [Face.F, Face.R, Face.B, Face.L];
  for (var face in sideFaces) {
    for (int c = 0; c < 3; c++) {
      sig.write(getColorCode(cube.grid[face.index][0][c]));
    }
  }

  return sig.toString();
}

bool isPLLResolved(RubiksCube cube, Color topColor) {
  final topFace = cube.grid[Face.U.index];
  final topLayerSolved = topFace.every((row) => row.every((color) => ColorUtils.areColorsEqual(color, topColor)));

  if (!topLayerSolved) return false;

  final sideCenters = <Face, Color>{
    Face.F: cube.getCenterColor(Face.F),
    Face.R: cube.getCenterColor(Face.R),
    Face.B: cube.getCenterColor(Face.B),
    Face.L: cube.getCenterColor(Face.L),
  };

  return sideCenters.entries.every((entry) {
    final face = entry.key;
    final expectedCenter = entry.value;
    return cube.grid[face.index][0][0] == expectedCenter &&
        cube.grid[face.index][0][1] == expectedCenter &&
        cube.grid[face.index][0][2] == expectedCenter;
  });
}