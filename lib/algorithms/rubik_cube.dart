import 'package:flutter/material.dart';
import '../color_utils.dart';

enum Face { F, R, U, B, L, D }

enum Move {
  F, FPrime, F2, f, fPrime, f2,
  R, RPrime, R2, r, rPrime, r2,
  U, UPrime, U2, u, uPrime, u2,
  B, BPrime, B2, b, bPrime, b2,
  L, LPrime, L2, l, lPrime, l2,
  D, DPrime, D2, d, dPrime, d2,
  M, MPrime, M2,
  x, xPrime,
  y, yPrime,
  z, zPrime
}

class RubiksCube {
  // 3D Grid mapping: [Face][Row][Column]
  List<List<List<Color>>> grid;

  RubiksCube(this.grid);

  RubiksCube clone() {
    final clonedGrid = List.generate(
      6,
      (faceIndex) => List.generate(
        3,
        (row) => List.generate(3, (col) => grid[faceIndex][row][col]),
      ),
    );
    return RubiksCube(clonedGrid);
  }

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
      case 'F': return Move.F;
      case "F'": return Move.FPrime;
      case 'F2': return Move.F2;
      case 'f': return Move.f;
      case "f'": return Move.fPrime;
      case "f2": return Move.f2;

      case 'R': return Move.R;
      case "R'": return Move.RPrime;
      case 'R2': return Move.R2;
      case 'r': return Move.r;
      case "r'": return Move.rPrime;
      case "r2": return Move.r2;

      case 'U': return Move.U;
      case "U'": return Move.UPrime;
      case 'U2': return Move.U2;
      case 'u': return Move.u;
      case "u'": return Move.uPrime;
      case "u2": return Move.u2;

      case 'B': return Move.B;
      case "B'": return Move.BPrime;
      case 'B2': return Move.B2;
      case 'b': return Move.b;
      case "b'": return Move.bPrime;
      case "b2": return Move.b2;

      case 'L': return Move.L;
      case "L'": return Move.LPrime;
      case 'L2': return Move.L2;
      case 'l': return Move.l;
      case "l'": return Move.lPrime;
      case "l2": return Move.l2;

      case 'D': return Move.D;
      case "D'": return Move.DPrime;
      case 'D2': return Move.D2;
      case 'd': return Move.d;
      case "d'": return Move.dPrime;
      case "d2": return Move.d2;

      case 'M': return Move.M;
      case "M'": return Move.MPrime;
      case 'M2': return Move.M2;

      case 'x': return Move.x;
      case "x'": return Move.xPrime;
      case 'y': return Move.y;
      case "y'": return Move.yPrime;
      case 'z': return Move.z;
      case "z'": return Move.zPrime;

      default: return null;
    }
  }

  /// Master function handling all moves via Whole-Cube Rotations.
  void applyMove(Move move) {
    switch (move) {
      case Move.U:
        _rotateFaceClockwise(Face.U);
        _shiftHorizontalRing(clockwise: true);
        break;
      case Move.UPrime:
        _rotateFaceCounterClockwise(Face.U);
        _shiftHorizontalRing(clockwise: false);
        break;
      case Move.U2:
        applyMove(Move.U);
        applyMove(Move.U);
        break;

      case Move.u:
        applyMove(Move.DPrime);
        rotateCubeY();
        break;
      case Move.uPrime:
        applyMove(Move.D);
        _rotateCubeYPrime();
        break;
      case Move.u2:
        applyMove(Move.u);
        applyMove(Move.u);
        break;

      case Move.D:
        _rotateCubeX();
        _rotateCubeX();
        applyMove(Move.U);
        _rotateCubeX();
        _rotateCubeX();
        break;
      case Move.DPrime:
        _rotateCubeX();
        _rotateCubeX();
        applyMove(Move.UPrime);
        _rotateCubeX();
        _rotateCubeX();
        break;
      case Move.D2:
        applyMove(Move.D);
        applyMove(Move.D);
        break;

      case Move.d:
        applyMove(Move.U);
        _rotateCubeYPrime();
        break;
      case Move.dPrime:
        applyMove(Move.UPrime);
        rotateCubeY();
        break;
      case Move.d2:
        applyMove(Move.d);
        applyMove(Move.d);
        break;

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
      case Move.R2:
        applyMove(Move.R);
        applyMove(Move.R);
        break;

      case Move.r:
        applyMove(Move.LPrime);
        _rotateCubeX();
        break;
      case Move.rPrime:
        applyMove(Move.L);
        _rotateCubeXPrime();
        break;
      case Move.r2:
        applyMove(Move.r);
        applyMove(Move.r);
        break;

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
      case Move.L2:
        applyMove(Move.L);
        applyMove(Move.L);
        break;

      case Move.l:
        applyMove(Move.RPrime);
        _rotateCubeXPrime();
        break;
      case Move.lPrime:
        applyMove(Move.R);
        _rotateCubeX();
        break;
      case Move.l2:
        applyMove(Move.l);
        applyMove(Move.l);
        break;

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
      case Move.F2:
        applyMove(Move.F);
        applyMove(Move.F);
        break;

      case Move.f:
        applyMove(Move.BPrime);
        _rotateCubeZ();
        break;
      case Move.fPrime:
        applyMove(Move.B);
        _rotateCubeZPrime();
        break;
      case Move.f2:
        applyMove(Move.f);
        applyMove(Move.f);
        break;

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
      case Move.B2:
        applyMove(Move.B);
        applyMove(Move.B);
        break;

      case Move.b:
        applyMove(Move.FPrime);
        _rotateCubeZPrime();
        break;
      case Move.bPrime:
        applyMove(Move.F);
        _rotateCubeZ();
        break;
      case Move.b2:
        applyMove(Move.b);
        applyMove(Move.b);
        break;

      case Move.M:
        applyMove(Move.L);
        applyMove(Move.RPrime);
        _rotateCubeXPrime();
        break;
      case Move.MPrime:
        applyMove(Move.LPrime);
        applyMove(Move.R);
        _rotateCubeX();
        break;
      case Move.M2:
        applyMove(Move.M);
        applyMove(Move.M);
        break;

      case Move.x:
        _rotateCubeX();
        break;
      case Move.xPrime:
        _rotateCubeXPrime();
        break;
      case Move.y:
        rotateCubeY();
        break;
      case Move.yPrime:
        _rotateCubeYPrime();
        break;
      case Move.z:
        _rotateCubeZ();
        break;
      case Move.zPrime:
        _rotateCubeZPrime();
        break;

      default:
        break;
    }
  }

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

  /// Shifts the outer row 0 across adjacent side faces (F -> L -> B -> R).
  void _shiftHorizontalRing({required bool clockwise}) {
    int f = Face.F.index;
    int r = Face.R.index;
    int b = Face.B.index;
    int l = Face.L.index;

    List<Color> tempF = [grid[f][0][0], grid[f][0][1], grid[f][0][2]];

    if (clockwise) {
      for (int i = 0; i < 3; i++) { grid[f][0][i] = grid[r][0][i]; }
      for (int i = 0; i < 3; i++) { grid[r][0][i] = grid[b][0][i]; }
      for (int i = 0; i < 3; i++) { grid[b][0][i] = grid[l][0][i]; }
      for (int i = 0; i < 3; i++) { grid[l][0][i] = tempF[i]; }
    } else {
      for (int i = 0; i < 3; i++) { grid[f][0][i] = grid[l][0][i]; }
      for (int i = 0; i < 3; i++) { grid[l][0][i] = grid[b][0][i]; }
      for (int i = 0; i < 3; i++) { grid[b][0][i] = grid[r][0][i]; }
      for (int i = 0; i < 3; i++) { grid[r][0][i] = tempF[i]; }
    }
  }

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

  /// Rotates the entire cube along the X-axis (Rolls forward, Front goes Up).
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

  /// Rotates the entire cube along the X-axis in reverse (Rolls backward, Front goes Down).
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

  /// Rotates the entire cube horizontally around the Y-axis (Looking from the top).
  void rotateCubeY() {
    _rotateFaceClockwise(Face.U);
    _rotateFaceCounterClockwise(Face.D);

    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);

    grid[Face.F.index] = oldR;
    grid[Face.R.index] = oldB;
    grid[Face.B.index] = oldL;
    grid[Face.L.index] = oldF;
  }

  void _rotateCubeYPrime() {
    _rotateFaceCounterClockwise(Face.U);
    _rotateFaceClockwise(Face.D);

    var oldF = _getClonedFace(Face.F);
    var oldR = _getClonedFace(Face.R);
    var oldB = _getClonedFace(Face.B);
    var oldL = _getClonedFace(Face.L);

    grid[Face.F.index] = oldL;
    grid[Face.R.index] = oldF;
    grid[Face.B.index] = oldR;
    grid[Face.L.index] = oldB;
  }

  /// Rotates the entire cube along the Z-axis (Tilts right, Up goes Right).
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

  /// Rotates the entire cube along the Z-axis in reverse (Tilts left, Up goes Left).
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
}

bool matchEdge(
  RubiksCube cube,
  Face f1,
  int r1,
  int c1,
  Face f2,
  int r2,
  int c2,
  Color target1,
  Color target2,
) {
  Color clr1 = cube.grid[f1.index][r1][c1];
  Color clr2 = cube.grid[f2.index][r2][c2];

  return (ColorUtils.areColorsEqual(clr1, target1) && ColorUtils.areColorsEqual(clr2, target2)) ||
      (ColorUtils.areColorsEqual(clr1, target2) && ColorUtils.areColorsEqual(clr2, target1));
}

bool matchCorner(
  RubiksCube cube,
  Face f1,
  int r1,
  int c1,
  Face f2,
  int r2,
  int c2,
  Face f3,
  int r3,
  int c3,
  Color t1,
  Color t2,
  Color t3,
) {
  List<Color> currentColors = [
    cube.grid[f1.index][r1][c1],
    cube.grid[f2.index][r2][c2],
    cube.grid[f3.index][r3][c3],
  ];

  bool found1 = false;
  bool found2 = false;
  bool found3 = false;

  for (var color in currentColors) {
    if (ColorUtils.areColorsEqual(color, t1) && !found1) {
      found1 = true;
    } else if (ColorUtils.areColorsEqual(color, t2) && !found2) {
      found2 = true;
    } else if (ColorUtils.areColorsEqual(color, t3) && !found3) {
      found3 = true;
    }
  }

  return found1 && found2 && found3;
}
