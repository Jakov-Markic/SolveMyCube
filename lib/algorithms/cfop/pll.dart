import 'package:flutter/material.dart';
import 'cfop.dart';

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

  bool matchColors(Color c1, Color c2) => 
      c1.red == c2.red && c1.green == c2.green && c1.blue == c2.blue;

  // 1. Loop through all 4 whole-cube angles (Y axis)
  for (int yRot = 0; yRot < 4; yRot++) {
    
    // 2. Loop through all 4 top-layer angles (U axis)
    for (int uRot = 0; uRot < 4; uRot++) {
      String currentSignature = _getPLLSignature(cube);

      // --- Check A: PLL is already solved (or solved after U rotation / PLL Skip) ---
      if (currentSignature == "000111222333") {
        int aufAttempts = 0;
        while (!matchColors(cube.grid[Face.F.index][0][1], cube.getCenterColor(Face.F))) {
          cube.executeSequence("U");
          steps.write("U ");
          aufAttempts++;
          if (aufAttempts >= 4) throw StateError("Final AUF alignment failed.");
        }
        return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      }

      // --- Check B: Active PLL algorithm match ---
      if (standardPLLAlgorithms.containsKey(currentSignature)) {
        String algorithm = standardPLLAlgorithms[currentSignature]!;
        cube.executeSequence(algorithm);
        steps.write("$algorithm ");
        
        // Final AUF Alignment
        int aufAttempts = 0;
        while (!matchColors(cube.grid[Face.F.index][0][1], cube.getCenterColor(Face.F))) {
          cube.executeSequence("U");
          steps.write("U ");
          aufAttempts++;
          if (aufAttempts >= 4) throw StateError("Final AUF alignment failed.");
        }
        
        return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      }

      // Turn top layer to search for the next rotation
      cube.executeSequence("U");
      steps.write("U ");
    }

    // Rotate the entire cube to check the next spatial angle profile
    cube.rotateCubeY();
    steps.write("y ");
  }

  throw StateError("Cube is in an invalid PLL state or signature is missing from database.");
}

String _getPLLSignature(RubiksCube cube) {
  StringBuffer sig = StringBuffer();

  Color colorF = cube.getCenterColor(Face.F);
  Color colorR = cube.getCenterColor(Face.R);
  Color colorB = cube.getCenterColor(Face.B);
  Color colorL = cube.getCenterColor(Face.L);

  String getColorCode(Color color) {
    bool match(Color c1, Color c2) => c1.red == c2.red && c1.green == c2.green && c1.blue == c2.blue;
    if (match(color, colorF)) return "0";
    if (match(color, colorR)) return "1";
    if (match(color, colorB)) return "2";
    if (match(color, colorL)) return "3";
    return "?";
  }

  // Uniform clockwise reading order matches your exact database layout keys
  final sideFaces = [Face.F, Face.R, Face.B, Face.L];
  for (var face in sideFaces) {
    for (int c = 0; c < 3; c++) {
      sig.write(getColorCode(cube.grid[face.index][0][c]));
    }
  }

  return sig.toString();
}