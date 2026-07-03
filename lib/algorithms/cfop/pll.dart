/* import 'cfop.dart';


String solvePLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  // --- STEP 1: Permute Corners (Look for Headlights) ---
  bool foundHeadlights = false;
  int headlightRotations = 0;

  for (int i = 0; i < 4; i++) {
    if (cube.grid[Face.F.index][0][0] == cube.grid[Face.F.index][0][2]) {
      foundHeadlights = true;
      break;
    }
    cube.executeSequence("U");
    steps.write("U ");
    headlightRotations++;
  }

  if (foundHeadlights) {
    // Move headlights to the Left face so T-Perm can process them
    cube.executeSequence("U"); 
    steps.write("U ");
    
    // Execute T-Perm algorithm to fix all corners relative to each other
    String tPerm = "R U R' U' R' F R2 U' R' U' R U R' F'";
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
  } else {
    // No headlights exist anywhere (E-Perm/V-Perm scenario)
    // Run an initial T-Perm to create a set of headlights, then process them
    String tPerm = "R U R' U' R' F R2 U' R' U' R U R' F'";
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
    
    // Find where the new headlights landed and put them on the Left Face
    /* while (cube.grid[Face.L.index][0][0] != cube.grid[Face.L.index][0][2]) {
      cube.executeSequence("U");
      steps.write("U ");
    } */
    int uAttempts = 0;
    while (cube.grid[Face.U.index][0][1] != cube.grid[Face.U.index][0][2]) {
      cube.executeSequence("U");
      steps.write("U ");
      uAttempts++;
      if (uAttempts >= 4) {
        throw StateError('PLL failed after 4 U turns — condition unreachable.');
      }
    }
    
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
  }

  // Align corners to their actual matching side centers
  /* while (cube.grid[Face.F.index][0][0] != cube.getCenterColor(Face.F)) {
    cube.executeSequence("U");
    steps.write("U ");
  } */
  int uAttempts = 0;
    while (cube.grid[Face.U.index][0][0] != cube.getCenterColor(Face.F)) {
      cube.executeSequence("U");
      steps.write("U ");
      uAttempts++;
      if (uAttempts >= 4) {
        throw StateError('PLL failed after 4 U turns — condition unreachable.');
      }
    }

  // --- STEP 2: Permute Edges (U-Perm Loop) ---
  // All corners are now solved. Only edges remain.
  int safetyTimeout = 0;
  while (!cube.checkPLL() && safetyTimeout < 6) {
    safetyTimeout++;

    // Find if there is a fully completed side face bar
    int solvedSideOffset = -1;
    List<Face> sides = [Face.B, Face.L, Face.F, Face.R]; // Order matching standard back-placement
    for (int i = 0; i < 4; i++) {
      Face face = sides[i];
      if (cube.grid[face.index][0][0] == cube.grid[face.index][0][1]) {
        solvedSideOffset = i;
        break;
      }
    }

    if (solvedSideOffset != -1) {
      // Rotate the entire cube so that the fully solved side face is facing Back (B)
      for (int i = 0; i < solvedSideOffset; i++) {
        cube.rotateCubeY();
        //steps.write("Y ");
      }
    }

    // Apply the standard clockwise U-Perm edge cycler
    String uPerm = "R2 U R U R' U' R' U' R' U R'";
    cube.executeSequence(uPerm);
    steps.write("$uPerm ");

    // Rotate the cube back if we turned it using Y
    if (solvedSideOffset != -1) {
      for (int i = 0; i < (4 - solvedSideOffset) % 4; i++) {
        cube.rotateCubeY();
      }
    }
  }

  // Final alignment adjustment layer shift
  /* while (cube.grid[Face.F.index][0][0] != cube.getCenterColor(Face.F)) {
    cube.executeSequence("U");
    steps.write("U ");
  } */
  uAttempts = 0;
    while (cube.grid[Face.U.index][0][0] != cube.getCenterColor(Face.F)) {
      cube.executeSequence("U");
      steps.write("U ");
      uAttempts++;
      if (uAttempts >= 4) {
        throw StateError('OLL L-shape alignment failed after 4 U turns — condition unreachable.');
      }
    }

  return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
} */

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

  // A full PLL case might require an initial U turn (Pre-AUF) to match the algorithm's angle
  for (int rotation = 0; rotation < 4; rotation++) {
    String currentSignature = _getPLLSignature(cube);

    if (standardPLLAlgorithms.containsKey(currentSignature)) {
      String algorithm = standardPLLAlgorithms[currentSignature]!;
      cube.executeSequence(algorithm);
      steps.write("$algorithm ");
      
      // --- Final AUF (Alignment of Upper Face) ---
      // The algorithm permutes the pieces correctly relative to each other, 
      // but the entire layer might need a final turn to match its side centers.
      int aufAttempts = 0;
      while (cube.grid[Face.F.index][0][1] != cube.getCenterColor(Face.F)) {
        cube.executeSequence("U");
        steps.write("U ");
        aufAttempts++;
        if (aufAttempts >= 4) {
          throw StateError("PLL executed successfully, but final AUF alignment failed.");
        }
      }
      
      return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    }

    // If no case matches the current orientation, turn the U layer and try again
    cube.executeSequence("U");
    steps.write("U ");
  }

  throw StateError("Cube is in an invalid PLL state or the case signature isn't in the 21-PLL database.");
}

/// Generates a strict 12-character relative color index string signature of the side layer states.
String _getPLLSignature(RubiksCube cube) {
  StringBuffer sig = StringBuffer();

  // Fetch the fixed center colors for side reference
  Color colorF = cube.getCenterColor(Face.F);
  Color colorR = cube.getCenterColor(Face.R);
  Color colorB = cube.getCenterColor(Face.B);
  Color colorL = cube.getCenterColor(Face.L);

  // Helper method to translate a sticker color into a relative index string
  String getColorCode(Color color) {
    if (color == colorF) return "0";
    if (color == colorR) return "1";
    if (color == colorB) return "2";
    if (color == colorL) return "3";
    return "?"; // Error boundary safeguard for un-unwrapped/corrupt states
  }

  // Read adjacent outer top stickers clockwise: Front, Right, Back, Left
  // 1. Front face top row
  for (int c = 0; c < 3; c++) {
    sig.write(getColorCode(cube.grid[Face.F.index][0][c]));
  }
  // 2. Right face top row
  for (int c = 0; c < 3; c++) {
    sig.write(getColorCode(cube.grid[Face.R.index][0][c]));
  }
  // 3. Back face top row
  for (int c = 0; c < 3; c++) {
    sig.write(getColorCode(cube.grid[Face.B.index][0][c]));
  }
  // 4. Left face top row
  for (int c = 0; c < 3; c++) {
    sig.write(getColorCode(cube.grid[Face.L.index][0][c]));
  }

  return sig.toString();
}