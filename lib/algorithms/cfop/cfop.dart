import 'package:flutter/material.dart';
import 'bottom_cross.dart';
import 'f2l.dart';
import 'oll.dart';
import 'pll.dart';
import '../rubik_cube.dart';

export '../rubik_cube.dart';

extension CfopRubiksCubeExtension on RubiksCube {
  bool checkBottomCross() {
    Color targetD = getCenterColor(Face.D);
    if (grid[Face.D.index][0][1] != targetD) return false;
    if (grid[Face.D.index][1][2] != targetD) return false;
    if (grid[Face.D.index][2][1] != targetD) return false;
    if (grid[Face.D.index][1][0] != targetD) return false;

    if (grid[Face.F.index][2][1] != getCenterColor(Face.F)) return false;
    if (grid[Face.R.index][2][1] != getCenterColor(Face.R)) return false;
    if (grid[Face.B.index][2][1] != getCenterColor(Face.B)) return false;
    if (grid[Face.L.index][2][1] != getCenterColor(Face.L)) return false;
    return true;
  }

  bool checkF2L() {
    List<Face> sides = [Face.F, Face.R, Face.B, Face.L];
    for (var face in sides) {
      Color centerColor = getCenterColor(face);
      for (int r = 1; r <= 2; r++) {
        for (int c = 0; c < 3; c++) {
          if (grid[face.index][r][c] != centerColor) return false;
        }
      }
    }
    return true;
  }

  bool checkOLL() {
    Color targetU = getCenterColor(Face.U);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (grid[Face.U.index][r][c] != targetU) return false;
      }
    }
    return true;
  }

  bool checkPLL() {
    for (var face in Face.values) {
      Color centerColor = getCenterColor(face);
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          if (grid[face.index][r][c] != centerColor) return false;
        }
      }
    }
    return true;
  }
}

// --- CFOP SOLVER ENGINE ---

String solveCfop(List<List<List<Color>>> cubeFaces) {
  RubiksCube cube = RubiksCube(cubeFaces);
  StringBuffer completeSolution = StringBuffer();

  // 1. Cross Phase
  if (!cube.checkBottomCross()) {
    String crossSteps = solveBottomCross(cube);
    completeSolution.write("$crossSteps ");
  }

  // 2. F2L Phase
  if (!cube.checkF2L()) {
    String f2lSteps = solveF2L(cube);
    completeSolution.write("$f2lSteps ");
  }

  print("\n\n$completeSolution\n\n");

  // 3. OLL Phase
  if (!cube.checkOLL()) {
    String ollSteps = solveOLL(cube);
    completeSolution.write("$ollSteps ");
  }
  
  // 4. PLL Phase
  if (!cube.checkPLL()) {
    String pllSteps = solvePLL(cube);
    completeSolution.write(pllSteps);
  }

  String rawSolution = completeSolution.toString();

  // Minimize and return the clean solution string
  return optimizeAlgorithm(rawSolution);
}

/// Optimizes and minimizes a Rubik's Cube move sequence string.
/// Combines redundant turns (e.g., U U U -> U') and cancels out opposing turns (e.g., U U' -> empty).
String optimizeAlgorithm(String rawAlgorithm) {
  if (rawAlgorithm.trim().isEmpty) return "";

  List<String> rawTokens = rawAlgorithm.trim().split(RegExp(r'\s+'));
  List<_MoveToken> stack = [];

  for (String token in rawTokens) {
    _MoveToken? current = _MoveToken.parse(token);
    if (current == null) continue;

    bool merged = false;

    // Look backward down the stack to find if we can merge same-face moves
    for (int i = stack.length - 1; i >= 0; i--) {
      if (stack[i].face == current.face) {
        stack[i].turns = (stack[i].turns + current.turns) % 4;

        if (stack[i].turns == 0) {
          stack.removeAt(i);
        }
        merged = true;
        break;
      }

      if (!_doFacesCommute(stack[i].face, current.face)) {
        break;
      }
    }

    if (!merged) {
      stack.add(current);
    }
  }

  return stack
      .map((m) => m.toString())
      .where((str) => str.isNotEmpty)
      .join(" ");
}

class _MoveToken {
  final String face;
  int turns; // 1 = Clockwise, 2 = Double (2), 3 = Counter-clockwise (')

  _MoveToken(this.face, this.turns);

  static _MoveToken? parse(String token) {
    if (token.isEmpty) return null;

    String face = token;
    int turns = 1;

    if (token.endsWith("'")) {
      face = token.substring(0, token.length - 1);
      turns = 3;
    } else if (token.endsWith("2")) {
      face = token.substring(0, token.length - 1);
      turns = 2;
    }

    return _MoveToken(face, turns);
  }

  @override
  String toString() {
    int count = turns % 4;
    if (count == 0) return "";
    if (count == 1) return face;
    if (count == 2) return "${face}2";
    if (count == 3) return "$face'";
    return "";
  }
}

bool _doFacesCommute(String f1, String f2) {
  if (f1 == f2) return true;

  String u1 = f1.toUpperCase();
  String u2 = f2.toUpperCase();

  const commutingPairs = {
    'U': 'D', 'D': 'U',
    'R': 'L', 'L': 'R',
    'F': 'B', 'B': 'F',
  };

  return commutingPairs[u1] == u2;
}