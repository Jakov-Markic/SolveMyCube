import 'package:flutter/material.dart';
import '../../color_utils.dart';
import 'cfop.dart';

// Hardcoded OLL patterns - these are the 57 known cases
// Format: 21-character string (9 U face + 3 each from F,R,B,L top rows)
final Map<String, String> standardOLLAlgorithms = {
  // Case 1: "R U2 R2 F R F' U2 R' F R F'"
  "000010000010111010111": "R U2 R2 F R F' U2 R' F R F'",
  
  // Case 2: "F R U R' U' F' f R U R' U' f'"
  "000010000011010110111": "F R U R' U' F' f R U R' U' f'",
  
  // Case 3: "f R U R' U' f' U' F R U R' U' F'"
  "000010001010011011011": "f R U R' U' f' U' F R U R' U' F'",
  
  // Case 4: "f R U R' U' f' U F R U R' U' F'"
  "001010000110110010110": "f R U R' U' f' U F R U R' U' F'",
  
  // Case 5: "l' U2 L U L' U l"
  "110110000011011000001": "l' U2 L U L' U l",
  
  // Case 6: "r U2 R' U' R U' r'"
  "011011000110100000110": "r U2 R' U' R U' r'",
  
  // Case 7: "r U R' U R U2 r'"
  "010110100011011001000": "r U R' U R U2 r'",
  
  // Case 8: "l' U' L U' L' U2 l"
  "010011001110000100110": "l' U' L U' L' U2 l",
  
  // Case 9: "R U R' U' R' F R2 U R' U' F'"
  "010110001110010100100": "R U R' U' R' F R2 U R' U' F'",
  
  // Case 10: "R U R' U R' F R F' R U2 R'"
  "001110010001010011001": "R U R' U R' F R F' R U2 R'",
  
  // Case 11: "r U R' U R' F R F' R U2 r'"
  "011110000011010001001": "r U R' U R' F R F' R U2 r'",
  
  // Case 12: "M' R' U' R U' R' U2 R U' R r'"
  "110011000110100100010": "M' R' U' R U' R' U2 R U' R r'",
  
  // Case 13: "F U R U' R2 F' R U R U' R'"
  "000111100011001011000": "F U R U' R2 F' R U R U' R'",
  
  // Case 14: "R' F R U R' F' R F U' F'"
  "000111001110000110100": "R' F R U R' F' R F U' F'",
  
  // Case 15: "l' U' l L' U' L U l' U l"
  "100111000011001010001": "l' U' l L' U' L U l' U l",
  
  // Case 16: "r U r' R U R' U' r U' r'"
  "001111000110100010100": "r U r' R U R' U' r U' r'",
  
  // Case 17: "F R' F' R2 r' U R U' R' U' M'"
  "100010001110011010010": "F R' F' R2 r' U R U' R' U' M'",
  
  // Case 18: "r U R' U R U2 r2 U' R U' R' U2 r"
  "101010000111010010010": "r U R' U R U2 r2 U' R U' R' U2 r",
  
  // Case 19: "M' U' r U2 r' U' R U' R' M'"
  "000000001100010100110": "M' U' r U2 r' U' R U' R' M'",
  
  // Case 20: "M U R U R' U' M2' U R U' r'"
  "101010101010010010010": "M U R U R' U' M2' U R U' r'",
  
  // Case 21: "R U2 R' U' R U R' U' R U' R'"
  "010111010101000101000": "R U2 R' U' R U R' U' R U' R'",
  
  // Case 22: "R U2 R2 U' R2 U' R2 U2 R"
  "010111010001000100101": "R U2 R2 U' R2 U' R2 U2 R",
  
  // Case 23: "R2 D' R U2 R' D R U2 R"
  "010111111000000101000": "R2 D' R U2 R' D R U2 R",
  
  // Case 24: "r U R' U' r' F R F'"
  "011111011100000001000": "r U R' U' r' F R F'",
  
  // Case 25: "F' r U R' U' r' F R"
  "011111110001000000100": "F' r U R' U' r' F R",
  
  // Case 26: "R U2 R' U' R U' R'"
  "011111010100100000100": "R U2 R' U' R U' R'",
  
  // Case 27: "R U R' U R U2 R'"
  "010111110001001001000": "R U R' U R U2 R'",
  
  // Case 28: "r U R' U' r' R U R U' R'"
  "111110101010010000000": "r U R' U' r' R U R U' R'",
  
  // Case 29: "R U R' U' R U' R' F' U' F R U R'"
  "011110001110010001000": "R U R' U' R U' R' F' U' F R U R'",
  
  // Case 30: "F R' F R2 U' R' U' R U R' F2"
  "010110101010011000100": "F R' F R2 U' R' U' R U R' F2",
  
  // Case 31: "R' U' F U R U' R' F' R"
  "011011001110000001010": "R' U' F U R U' R' F' R",
  
  // Case 32: "L U F' U' L' U L F L'"
  "110110100011010100000": "L U F' U' L' U L F L'",
  
  // Case 33: "R U R' U' R' F R F'"
  "001111001110000011000": "R U R' U' R' F R F'",
  
  // Case 34: "R U R2 U' R' F R U R U' F'"
  "000111101010001010100": "R U R2 U' R' F R U R U' F'",
  
  // Case 35: "R U2 R2 F R F' R U2 R'"
  "100011011100001010010": "R U2 R2 F R F' R U2 R'",
  
  // Case 36: "L' U' L U' L' U L U L F' L' F"
  "110011001010000100011": "L' U' L U' L' U L U L F' L' F",
  
  // Case 37: "F R' F' R U R U' R'"
  "110110001110011000000": "F R' F' R U R U' R'",
  
  // Case 38: "R U R' U R U' R' U' R' F R F'"
  "011110100010110001000": "R U R' U R U' R' U' R' F R F'",
  
  // Case 39: "L F' L' U' L U F U' L'"
  "001111100010100011000": "L F' L' U' L U F U' L'",
  
  // Case 40: "R' F R U R' U' F' U R"
  "100111001010000110001": "R' F R U R' U' F' U R",
  
  // Case 41: "R U R' U R U2 R' F R U R' U' F'"
  "010110101010010101000": "R U R' U R U2 R' F R U R' U' F'",
  
  // Case 42: "R' U' R U' R' U2 R F R U R' U' F'"
  "101110010101010010000": "R' U' R U' R' U2 R F R U R' U' F'",
  
  // Case 43: "F' U' L' U L F"
  "011011001010000000111": "F' U' L' U L F",
  
  // Case 44: "F U R U' R' F'"
  "110110100010111000000": "F U R U' R' F'",
  
  // Case 45: "F R U R' U' F'"
  "001111001010000010101": "F R U R' U' F'",
  
  // Case 46: "R' U' R' F R F' U R"
  "110010110000111000010": "R' U' R' F R F' U R",
  
  // Case 47: "R' U' R' F R F' R' F R F' U R"
  "010011000110101001010": "R' U' R' F R F' R' F R F' U R",
  
  // Case 48: "F R U R' U' R U R' U' F'"
  "010110000011010100101": "F R U R' U' R U R' U' F'",
  
  // Case 49: "r U' r2 U r2 U r2 U' r"
  "010011000011000100111": "r U' r2 U r2 U r2 U' r",
  
  // Case 50: "r' U r2 U' r2 U' r2 U r'"
  "000011010001000110111": "r' U r2 U' r2 U' r2 U r'",
  
  // Case 51: "F U R U' R' U R U' R' F'"
  "000111000110101011000": "F U R U' R' U R U' R' F'",
  
  // Case 52: "R U R' U R U' B U' B' R'"
  "010010010100111001010": "R U R' U R U' B U' B' R'",
  
  // Case 53: "l' U2 L U L' U' L U L' U l"
  "010011000111000101010": "l' U2 L U L' U' L U L' U l",
  
  // Case 54: "r U2 R' U' R U R' U' R U' r'"
  "010110000111010101000": "r U2 R' U' R U R' U' R U' r'",
  
  // Case 55: "R' F R U R U' R2 F' R2 U' R' U R U R'"
  "000111000111000111000": "R' F R U R U' R2 F' R2 U' R' U R U R'",
  
  // Case 56: "r' U' r U' R' U R U' R' U R r' U r"
  "000111000010101010101": "r' U' r U' R' U R U' R' U R r' U r",
  
  // Case 57: "R U R' U' M' U R U' r'"
  "101111101010000010000": "R U R' U' M' U R U' r'",
};

/// Gets OLL signature respecting the cube's CURRENT orientation
String _getOrientedOLLSignature(RubiksCube cube, Color targetU, Color targetF, 
    Color targetR, Color targetB, Color targetL) {
  StringBuffer sig = StringBuffer();

  String checkColor(Color? color, Color target) {
    if (color == null) return "0";
    return ColorUtils.areColorsEqual(color, target) ? "1" : "0";
  }

  // Find current face indices for each original face by center color
  int uIdx = _findFaceByCenter(cube, targetU);
  int fIdx = _findFaceByCenter(cube, targetF);
  int rIdx = _findFaceByCenter(cube, targetR);
  int bIdx = _findFaceByCenter(cube, targetB);
  int lIdx = _findFaceByCenter(cube, targetL);

  // Read U face (3x3 grid, row by row) - 9 stickers
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 3; c++) {
      sig.write(checkColor(cube.grid[uIdx][r][c], targetU));
    }
  }

  // Read top rows of side faces in clockwise order: F, R, B, L - 12 stickers
  // Front face top row (row 0, cols 0-2)
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[fIdx][0][c], targetU));
  }
  // Right face top row (row 0, cols 0-2)
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[rIdx][0][c], targetU));
  }
  // Back face top row (row 0, cols 0-2)
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[bIdx][0][c], targetU));
  }
  // Left face top row (row 0, cols 0-2)
  for (int c = 0; c < 3; c++) {
    sig.write(checkColor(cube.grid[lIdx][0][c], targetU));
  }

  return sig.toString();
}

int _findFaceByCenter(RubiksCube cube, Color centerColor) {
  for (int i = 0; i < 6; i++) {
    if (ColorUtils.areColorsEqual(cube.grid[i][1][1], centerColor)) {
      return i;
    }
  }
  throw StateError("Could not find face with center color");
}
String solveOLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();
  Color targetU = cube.getCenterColor(Face.U);
  
  if (cube.checkOLL()) {
    return "";
  }

  Color originalF = cube.getCenterColor(Face.F);
  Color originalR = cube.getCenterColor(Face.R);
  Color originalB = cube.getCenterColor(Face.B);
  Color originalL = cube.getCenterColor(Face.L);
  
  Color currentF = originalF;
  Color currentR = originalR;
  Color currentB = originalB;
  Color currentL = originalL;

  // Try all 4 U rotations in current orientation
  for (int uRot = 0; uRot < 4; uRot++) {
    String currentSignature = _getOrientedOLLSignature(
      cube, targetU, currentF, currentR, currentB, currentL);
    
    print("Trying signature (U rotation $uRot): $currentSignature");
    
    if (standardOLLAlgorithms.containsKey(currentSignature)) {
      String algorithm = standardOLLAlgorithms[currentSignature]!;
      
      // Apply U setup moves AND write them to steps
      for (int i = 0; i < uRot; i++) {
        steps.write("U ");
      }
      
      cube.executeSequence(algorithm);
      steps.write(algorithm);
      
      print("Found OLL case! Algorithm: $algorithm");
      return steps.toString().trim();
    }
    
    // Only rotate cube for next iteration, DON'T write to steps
    cube.executeSequence("U");
  }
  
  // Reset the 4 U rotations we did
  // Actually we've done 4 U = U4 = back to start, so no need to undo
  
  // Try cube rotations
  for (int yRot = 1; yRot <= 4; yRot++) {
    cube.rotateCubeY();
    steps.write("y ");
    
    Color temp = currentF;
    currentF = currentL;
    currentL = currentB;
    currentB = currentR;
    currentR = temp;
    
    for (int uRot = 0; uRot < 4; uRot++) {
      String currentSignature = _getOrientedOLLSignature(
        cube, targetU, currentF, currentR, currentB, currentL);
      
      print("Trying signature (Y rot $yRot, U rot $uRot): $currentSignature");
      
      if (standardOLLAlgorithms.containsKey(currentSignature)) {
        String algorithm = standardOLLAlgorithms[currentSignature]!;
        
        for (int i = 0; i < uRot; i++) {
          cube.executeSequence("U");
          steps.write("U ");
        }
        
        cube.executeSequence(algorithm);
        steps.write(algorithm);
        
        print("Found OLL case with cube rotation! Algorithm: $algorithm");
        return steps.toString().trim();
      }
      
      cube.executeSequence("U");
    }
  }

  String finalSig = _getOrientedOLLSignature(
    cube, targetU, currentF, currentR, currentB, currentL);
  print("FAILED to find OLL. Final signature: $finalSig");
  
  throw StateError("OLL case not found in 57 standard cases. Signature: $finalSig");
}