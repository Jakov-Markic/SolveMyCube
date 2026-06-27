import 'package:flutter/material.dart';
import 'bottom_cross.dart';
import 'f2l.dart';
import 'ool.dart';
import 'pll.dart';

enum Face { F, R, U, B, L, D }

enum Move {
  F, FPrime,
  R, RPrime,
  U, UPrime,
  B, BPrime,
  L, LPrime,
  D, DPrime
}

class RubiksCube {
  // 3D Grid mapping: [Face][Row][Column]
  List<List<List<Color>>> grid;

  RubiksCube(this.grid);

  Color getCenterColor(Face face) => grid[face.index][1][1];

  /// Parses standard algorithm notation strings and executes them sequentially.
  void executeSequence(String sequence) {
    if (sequence.trim().isEmpty) return;
    List<String> tokens = sequence.split(RegExp(r'\s+'));
    for (String token in tokens) {
      Move? move = _parseToken(token);
      if (move != null) applyMove(move);
    }
  }

  Move? _parseToken(String token) {
    switch (token) {
      case 'F':  return Move.F;
      case "F'": return Move.FPrime;
      case 'R':  return Move.R;
      case "R'": return Move.RPrime;
      case 'U':  return Move.U;
      case "U'": return Move.UPrime;
      case 'B':  return Move.B;
      case "B'": return Move.BPrime;
      case 'L':  return Move.L;
      case "L'": return Move.LPrime;
      case 'D':  return Move.D;
      case "D'": return Move.DPrime;
      default:   return null;
    }
  }

  /// Master function handling all moves via Whole-Cube Rotations
  void applyMove(Move move) {
    switch (move) {
      // Base Core Move: Up (U)
      case Move.U:
        _rotateFaceClockwise(Face.U);
        _shiftHorizontalRing(clockwise: true);
        break;
      case Move.UPrime:
        _rotateFaceCounterClockwise(Face.U);
        _shiftHorizontalRing(clockwise: false);
        break;

      // Down (D) Move: Rotate cube upside down (X2), do a U move, rotate back
      case Move.D:
        _rotateCubeX(); _rotateCubeX();
        applyMove(Move.U);
        _rotateCubeX(); _rotateCubeX();
        break;
      case Move.DPrime:
        _rotateCubeX(); _rotateCubeX();
        applyMove(Move.UPrime);
        _rotateCubeX(); _rotateCubeX();
        break;

      // Right (R) Move: Tilt cube left (Z'), do a U move, tilt back (Z)
      case Move.R:
        _rotateCubeZPrime();
        applyMove(Move.U);
        _rotateCubeZ();
        break;
      case Move.RPrime:
        _rotateCubeZPrime();
        applyMove(Move.UPrime);
        _rotateCubeZ();
        break;

      // Left (L) Move: Tilt cube right (Z), do a U move, tilt back (Z')
      case Move.L:
        _rotateCubeZ();
        applyMove(Move.U);
        _rotateCubeZPrime();
        break;
      case Move.LPrime:
        _rotateCubeZ();
        applyMove(Move.UPrime);
        _rotateCubeZPrime();
        break;

      // Front (F) Move: Roll cube up (X), do a U move, roll back (X')
      case Move.F:
        _rotateCubeX();
        applyMove(Move.U);
        _rotateCubeXPrime();
        break;
      case Move.FPrime:
        _rotateCubeX();
        applyMove(Move.UPrime);
        _rotateCubeXPrime();
        break;

      // Back (B) Move: Roll cube down (X'), do a U move, roll back (X)
      case Move.B:
        _rotateCubeXPrime();
        applyMove(Move.U);
        _rotateCubeX();
        break;
      case Move.BPrime:
        _rotateCubeXPrime();
        applyMove(Move.UPrime);
        _rotateCubeX();
        break;
    }
  }

  // --- CORE LAYER MANIPULATION ---

  void _rotateFaceClockwise(Face face) {
    int f = face.index;
    List<List<Color>> temp = List.generate(3, (r) => List.generate(3, (c) => grid[f][r][c]));
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        grid[f][c][2 - r] = temp[r][c];
      }
    }
  }

  void _rotateFaceCounterClockwise(Face face) {
    int f = face.index;
    List<List<Color>> temp = List.generate(3, (r) => List.generate(3, (c) => grid[f][r][c]));
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        grid[f][2 - c][r] = temp[r][c];
      }
    }
  }

  /// Shifts the outer row 0 across adjacent side faces (F -> L -> B -> R)
  void _shiftHorizontalRing({required bool clockwise}) {
    int f = Face.F.index;
    int r = Face.R.index;
    int b = Face.B.index;
    int l = Face.L.index;

    List<Color> tempF = [grid[f][0][0], grid[f][0][1], grid[f][0][2]];

    if (clockwise) {
      for (int i = 0; i < 3; i++) grid[f][0][i] = grid[r][0][i];
      for (int i = 0; i < 3; i++) grid[r][0][i] = grid[b][0][i];
      for (int i = 0; i < 3; i++) grid[b][0][i] = grid[l][0][i];
      for (int i = 0; i < 3; i++) grid[l][0][i] = tempF[i];
    } else {
      for (int i = 0; i < 3; i++) grid[f][0][i] = grid[l][0][i];
      for (int i = 0; i < 3; i++) grid[l][0][i] = grid[b][0][i];
      for (int i = 0; i < 3; i++) grid[b][0][i] = grid[r][0][i];
      for (int i = 0; i < 3; i++) grid[r][0][i] = tempF[i];
    }
  }

  // --- GLOBAL WHOLE-CUBE ROTATIONS ---

  List<List<Color>> _getClonedFace(Face face) {
    return List.generate(3, (r) => List.generate(3, (c) => grid[face.index][r][c]));
  }

  List<List<Color>> _get180RotatedFace(List<List<Color>> faceMatrix) {
    return List.generate(3, (r) => List.generate(3, (c) => faceMatrix[2 - r][2 - c]));
  }

  List<List<Color>> _getClockwiseRotatedFace(List<List<Color>> faceMatrix) {
    return List.generate(3, (r) => List.generate(3, (c) => faceMatrix[2 - c][r]));
  }

  List<List<Color>> _getCounterClockwiseRotatedFace(List<List<Color>> faceMatrix) {
    return List.generate(3, (r) => List.generate(3, (c) => faceMatrix[c][2 - r]));
  }

  /// Rotates the entire cube along the X-axis (Rolls forward, Front goes Up)
  void _rotateCubeX() {
    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldU = _getClonedFace(Face.U);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);
    var oldD = _getClonedFace(Face.D);

    grid[Face.U.index] = oldF;
    grid[Face.B.index] = _get180RotatedFace(oldU);
    grid[Face.D.index] = _get180RotatedFace(oldB);
    grid[Face.F.index] = oldD;

    grid[Face.R.index] = _getClockwiseRotatedFace(oldR);
    grid[Face.L.index] = _getCounterClockwiseRotatedFace(oldL);
  }

  /// Rotates the entire cube along the X-axis in reverse (Rolls backward, Front goes Down)
  void _rotateCubeXPrime() {
    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldU = _getClonedFace(Face.U);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);
    var oldD = _getClonedFace(Face.D);

    grid[Face.D.index] = oldF;
    grid[Face.B.index] = _get180RotatedFace(oldD);
    grid[Face.U.index] = _get180RotatedFace(oldB);
    grid[Face.F.index] = oldU;

    grid[Face.R.index] = _getCounterClockwiseRotatedFace(oldR);
    grid[Face.L.index] = _getClockwiseRotatedFace(oldL);
  }

  /// Rotates the entire cube horizontally around the Y-axis (Looking from the top)
  void _rotateCubeY() {
    _rotateFaceClockwise(Face.U);
    _rotateFaceCounterClockwise(Face.D);
    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);
    
    grid[Face.L.index] = oldF;
    grid[Face.B.index] = oldR;
    grid[Face.R.index] = oldB;
    grid[Face.F.index] = oldL;
  }

  /// Rotates the entire cube along the Z-axis (Tilts right, Up goes Right)
  void _rotateCubeZ() {
    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldU = _getClonedFace(Face.U);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);
    var oldD = _getClonedFace(Face.D);

    grid[Face.R.index] = _getClockwiseRotatedFace(oldU);
    grid[Face.D.index] = _getClockwiseRotatedFace(oldR);
    grid[Face.L.index] = _getClockwiseRotatedFace(oldD);
    grid[Face.U.index] = _getClockwiseRotatedFace(oldL);

    grid[Face.F.index] = _getClockwiseRotatedFace(oldF);
    grid[Face.B.index] = _getCounterClockwiseRotatedFace(oldB);
  }

  /// Rotates the entire cube along the Z-axis in reverse (Tilts left, Up goes Left)
  void _rotateCubeZPrime() {
    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldU = _getClonedFace(Face.U);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);
    var oldD = _getClonedFace(Face.D);

    grid[Face.L.index] = _getCounterClockwiseRotatedFace(oldU);
    grid[Face.D.index] = _getCounterClockwiseRotatedFace(oldL);
    grid[Face.R.index] = _getCounterClockwiseRotatedFace(oldD);
    grid[Face.U.index] = _getCounterClockwiseRotatedFace(oldR);

    grid[Face.F.index] = _getCounterClockwiseRotatedFace(oldF);
    grid[Face.B.index] = _getClockwiseRotatedFace(oldB);
  }

  // --- STATE CHECKERS ---

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
    if (!checkBottomCross()) return false;
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
    if (!checkF2L()) return false;
    Color targetU = getCenterColor(Face.U);
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (grid[Face.U.index][r][c] != targetU) return false;
      }
    }
    return true;
  }

  bool checkPLL() {
    if (!checkOLL()) return false;
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
    cube.executeSequence(crossSteps);
    completeSolution.write("$crossSteps ");
  }

  // 2. F2L Phase
  if (!cube.checkF2L()) {
    String f2lSteps = solveF2L(cube);
    cube.executeSequence(f2lSteps);
    completeSolution.write("$f2lSteps ");
  }

  // 3. OLL Phase
  if (!cube.checkOLL()) {
    String ollSteps = solveOLL(cube);
    cube.executeSequence(ollSteps);
    completeSolution.write("$ollSteps ");
  }

  // 4. PLL Phase
  if (!cube.checkPLL()) {
    String pllSteps = solvePLL(cube);
    cube.executeSequence(pllSteps);
    completeSolution.write("$pllSteps");
  }

  return completeSolution.toString().trim();
}
// --- UNIVERSAL TRACKING HELPERS ---

bool matchEdge(RubiksCube cube, Face f1, int r1, int c1, Face f2, int r2, int c2, Color target1, Color target2) {
  Color clr1 = cube.grid[f1.index][r1][c1];
  Color clr2 = cube.grid[f2.index][r2][c2];
  return (clr1 == target1 && clr2 == target2) || (clr1 == target2 && clr2 == target1);
}

bool matchCorner(RubiksCube cube, Face f1, int r1, int c1, Face f2, int r2, int c2, Face f3, int r3, int c3, Color t1, Color t2, Color t3) {
  List<Color> currentColors = [
    cube.grid[f1.index][r1][c1],
    cube.grid[f2.index][r2][c2],
    cube.grid[f3.index][r3][c3]
  ];
  return currentColors.contains(t1) && currentColors.contains(t2) && currentColors.contains(t3);
}
