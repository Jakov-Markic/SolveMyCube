/* import 'package:flutter/material.dart';

import 'cfop.dart';


String solveOLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();
  Color targetU = cube.getCenterColor(Face.U);

  // --- STEP 1: Orient Edges (Get the Yellow Cross) ---
  int edgeCount = 0;
  if (cube.grid[Face.U.index][0][1] == targetU) edgeCount++; // Back edge
  if (cube.grid[Face.U.index][1][0] == targetU) edgeCount++; // Left edge
  if (cube.grid[Face.U.index][1][2] == targetU) edgeCount++; // Right edge
  if (cube.grid[Face.U.index][2][1] == targetU) edgeCount++; // Front edge

  if (edgeCount == 0) {
    // Dot Case: Run Line algorithm, then L-shape algorithm
    cube.executeSequence("F R U R' U' F'");
    steps.write("F R U R' U' F' ");
    // Re-evaluate to handle the resulting L-shape
    edgeCount = 2; 
  }

  if (edgeCount == 2) {
    // Could be a Line or an L-shape. Let's align it.
    bool isLine = (cube.grid[Face.U.index][1][0] == targetU && cube.grid[Face.U.index][1][2] == targetU) ||
                  (cube.grid[Face.U.index][0][1] == targetU && cube.grid[Face.U.index][2][1] == targetU);

    if (isLine) {
      // Make sure the line is horizontal (Left-Right)
      if (cube.grid[Face.U.index][0][1] == targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
      cube.executeSequence("F R U R' U' F'");
      steps.write("F R U R' U' F' ");
    } else {
      // It's an L-shape. Rotate U until the L points Back and Left (0,1 and 1,0 are targetU)
      int uAttempts = 0;
      while (cube.grid[Face.U.index][0][1] != targetU || cube.grid[Face.U.index][1][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
        uAttempts++;
        if (uAttempts >= 4) {
          throw StateError('OLL L-shape alignment failed after 4 U turns — condition unreachable.');
        }
      }
      cube.executeSequence("F U R U' R' F'");
      steps.write("F U R U' R' F' ");
    }
  }

  // --- STEP 2: Orient Corners (Sune Loop) ---
  // Keep looping Sune until all 9 stickers on the U face match targetU
  int safetyTimeout = 0;
  while (!cube.checkOLL() && safetyTimeout < 8) {
    safetyTimeout++;
    int orientedCorners = 0;
    if (cube.grid[Face.U.index][0][0] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][0][2] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][2][0] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][2][2] == targetU) orientedCorners++;

    if (orientedCorners == 1) {
      // Sune Case: Rotate U until the single oriented corner is at the Front-Left (2,0)
      while (cube.grid[Face.U.index][2][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    } else if (orientedCorners == 2) {
      // Car/Chameleon structures: Rotate U until a yellow sticker faces Left at Front-Left-Up
      while (cube.grid[Face.L.index][0][2] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    } else if (orientedCorners == 0) {
      // Bowtie/Cross structures: Rotate U until a yellow sticker faces Front at Front-Left-Up
      while (cube.grid[Face.F.index][0][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    }

    cube.executeSequence("R U R' U R U2 R'");
    steps.write("R U R' U R U2 R' ");
  }

  return steps.toString().trim();
}
 */

import 'package:flutter/material.dart';
import 'cfop.dart';

// 1. Define the 57 standard OLL algorithms mapping (Case Number -> Algorithm)
final Map<String, String> standardOLLAlgorithms = {
  "000010000010111010111": "R U2 R2 F R F' U2 R' F R F'", // Case 1
  "000010000011010110111": "F R U R' U' F' f R U R' U' f'", // Case 2
  "000010001010011011011": "f R U R' U' f' U' F R U R' U' F'", // Case 3
  "001010000110110010110": "f R U R' U' f' U F R U R' U' F'", // Case 4
  "110110000011011000001": "l' U2 L U L' U l", // Case 5
  "011011000110100000110": "r U2 R' U' R U' r'", // Case 6
  "010110100011011001000": "r U R' U R U2 r'", // Case 7
  "010011001110000100110": "l' U' L U' L' U2 l", // Case 8
  "010110001110010100100": "R U R' U' R' F R2 U R' U' F'", // Case 9
  "001110010001010011001": "R U R' U R' F R F' R U2 R'", // Case 10
  "011110000011010001001": "r U R' U R' F R F' R U2 r'", // Case 11
  "110011000110100100010": "M' R' U' R U' R' U2 R U' R r'", // Case 12
  "000111100011001011000": "F U R U' R2 F' R U R U' R'", // Case 13
  "000111001110000110100": "R' F R U R' F' R F U' F'", // Case 14
  "100111000011001010001": "l' U' l L' U' L U l' U l", // Case 15
  "001111000110100010100": "r U r' R U R' U' r U' r'", // Case 16
  "100010001110011010010": "F R' F' R2 r' U R U' R' U' M'", // Case 17
  "101010000111010010010": "r U R' U R U2 r2 U' R U' R' U2 r", // Case 18
  "000000001100010100110": "M' U' r U2 r' U' R U' R' M'", // Case 19
  "101010101010010010010": "M U R U R' U' M2' U R U' r'", // Case 20
  "010111010101000101000": "R U2 R' U' R U R' U' R U' R'", // Case 21
  "010111010001000100101": "R U2 R2 U' R2 U' R2 U2 R", // Case 22
  "010111111000000101000": "R2 D' R U2 R' D R U2 R", // Case 23
  "011111011100000001000": "r U R' U' r' F R F'", // Case 24
  "011111110001000000100": "F' r U R' U' r' F R", // Case 25
  "011111010100100000100": "R U2 R' U' R U' R'", // Case 26
  "010111110001001001000": "R U R' U R U2 R'", // Case 27
  "111110101010010000000": "r U R' U' r' R U R U' R'", // Case 28
  "011110001110010001000": "R U R' U' R U' R' F' U' F R U R'", // Case 29
  "010110101010011000100": "F R' F R2 U' R' U' R U R' F2", // Case 30
  "011011001110000001010": "R' U' F U R U' R' F' R", // Case 31
  "110110100011010100000": "L U F' U' L' U L F L'", // Case 32
  "001111001110000011000": "R U R' U' R' F R F'", // Case 33
  "000111101010001010100": "R U R2 U' R' F R U R U' F'", // Case 34
  "100011011100001010010": "R U2 R2 F R F' R U2 R'", // Case 35
  "110011001010000100011": "L' U' L U' L' U L U L F' L' F", // Case 36
  "110110001110011000000": "F R' F' R U R U' R'", // Case 37
  "011110100010110001000": "R U R' U R U' R' U' R' F R F'", // Case 38
  "001111100010100011000": "L F' L' U' L U F U' L'", // Case 39
  "100111001010000110001": "R' F R U R' U' F' U R", // Case 40
  "010110101010010101000": "R U R' U R U2 R' F R U R' U' F'", // Case 41
  "101110010101010010000": "R' U' R U' R' U2 R F R U R' U' F'", // Case 42
  "011011001010000000111": "F' U' L' U L F", // Case 43
  "110110100010111000000": "F U R U' R' F'", // Case 44
  "001111001010000010101": "F R U R' U' F'", // Case 45
  "110010110000111000010": "R' U' R' F R F' U R", // Case 46
  "010011000110101001010": "R' U' R' F R F' R' F R F' U R", // Case 47
  "010110000011010100101": "F R U R' U' R U R' U' F'", // Case 48
  "010011000011000100111": "r U' r2 U r2 U r2 U' r", // Case 49
  "000011010001000110111": "r' U r2 U' r2 U' r2 U r'", // Case 50
  "000111000110101011000": "F U R U' R' U R U' R' F'", // Case 51
  "010010010100111001010": "R U R' U R U' B U' B' R'", // Case 52
  "010011000111000101010": "l' U2 L U L' U' L U L' U l", // Case 53
  "010110000111010101000": "r U2 R' U' R U R' U' R U' r'", // Case 54
  "000111000111000111000": "R' F R U R U' R2 F' R2 U' R' U R U R'", // Case 55
  "000111000010101010101": "r' U' r U' R' U R U' R' U R r' U r", // Case 56
  "101111101010000010000": "R U R' U' M' U R U' r'", // Case 57
};

String solveOLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();
  Color targetU = cube.getCenterColor(Face.U);

  // A full OLL case might be rotated. We check all 4 U-turn variations.
  for (int rotation = 0; rotation < 4; rotation++) {
    String currentSignature = _getOLLSignature(cube, targetU);

    if (standardOLLAlgorithms.containsKey(currentSignature)) {
      String algorithm = standardOLLAlgorithms[currentSignature]!;
      cube.executeSequence(algorithm);
      steps.write(algorithm);
      return steps.toString().trim();
    }

    // If no case matches the current orientation, turn the U layer and try again
    cube.executeSequence("U");
    steps.write("U ");
  }

  // If we reach here, either the state is invalid or a signature calculation is misaligned.
  throw StateError("Cube is in an invalid OLL state or the case signature isn't in the 57-OLL database.");
}

/// Generates a strict 21-character binary string signature of the top layer state.
String _getOLLSignature(RubiksCube cube, Color targetU) {
  StringBuffer sig = StringBuffer();

  // 1. Read the 9 stickers on the Up face (rows 0-2, cols 0-2)
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 3; c++) {
      sig.write(cube.grid[Face.U.index][r][c] == targetU ? "1" : "0");
    }
  }

  // 2. Read adjacent outer top stickers in a fixed order (Front, Right, Back, Left)
  // Front face top row
  for (int c = 0; c < 3; c++) {sig.write(cube.grid[Face.F.index][0][c] == targetU ? "1" : "0");}
  // Right face top row
  for (int c = 0; c < 3; c++) {sig.write(cube.grid[Face.R.index][0][c] == targetU ? "1" : "0");}
  // Back face top row
  for (int c = 0; c < 3; c++) {sig.write(cube.grid[Face.B.index][0][c] == targetU ? "1" : "0");}
  // Left face top row
  for (int c = 0; c < 3; c++) {sig.write(cube.grid[Face.L.index][0][c] == targetU ? "1" : "0");}

  return sig.toString();
}