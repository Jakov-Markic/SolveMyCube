import 'package:flutter/material.dart';
import '../../color_utils.dart';
import '../rubik_cube.dart';

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
  final targetU = cube.getCenterColor(Face.U);
  final steps = StringBuffer();

  for (int cubeRotation = 0; cubeRotation < 4; cubeRotation++) {
    for (int topRotation = 0; topRotation < 4; topRotation++) {
      final candidate = cube.clone();

      for (int i = 0; i < cubeRotation; i++) {
        candidate.executeSequence('y');
      }
      for (int i = 0; i < topRotation; i++) {
        candidate.executeSequence('U');
      }

      final signature = getOLLSignature(candidate, targetU);
      if (standardOLLAlgorithms.containsKey(signature)) {
        for (int i = 0; i < cubeRotation; i++) {
          cube.executeSequence('y');
          steps.write('y ');
        }
        for (int i = 0; i < topRotation; i++) {
          cube.executeSequence('U');
          steps.write('U ');
        }

        final algorithm = standardOLLAlgorithms[signature]!;
        cube.executeSequence(algorithm);
        steps.write(algorithm);
        return steps.toString().trim();
      }
    }
  }

  throw StateError('Cube is in an invalid OLL state or the case signature is not in the 57-OLL database.');
}

String getOLLSignature(RubiksCube cube, Color targetU) {
  final sig = StringBuffer();

  String checkColor(Color? gridColor) {
    if (gridColor == null) return '0';
    return ColorUtils.areColorsEqual(gridColor, targetU) ? '1' : '0';
  }

  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 3; c++) {
      sig.write(checkColor(cube.grid[Face.U.index][r][c]));
    }
  }

  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[Face.F.index][0][c]));
  }
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[Face.R.index][0][c]));
  }
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[Face.B.index][0][c]));
  }
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[Face.L.index][0][c]));
  }

  return sig.toString();
}