import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

void main() {
  final scramble = "L' U2 R' U' B2 R' L D";
  final cube = RubiksCube(_createSolvedCube());
  cube.executeSequence(scramble);

  print('Scramble: $scramble');
  _printCrossState(cube, 'After scramble');
  _debugSolveBottomCross(cube);
}

void _debugSolveBottomCross(RubiksCube cube) {
  final cD = cube.getCenterColor(Face.D);
  final cF = cube.getCenterColor(Face.F);

  print('Target D color: ${_colorValue(cD)}, F color: ${_colorValue(cF)}');

  for (int i = 0; i < 4; i++) {
    print('\n-- iteration ${i + 1} --');
    _printCrossState(cube, 'Start of iteration');

    if (ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][1], cD) &&
        ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][1], cF)) {
      print('Slot already solved; rotating y');
      cube.rotateCubeY();
      continue;
    }

    print('Slot not solved; checking bottom layer piece');
    if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF) ||
        matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF) ||
        matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF) ||
        matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) {
      print('Piece found in bottom layer');
      if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF)) {
        print('Piece is in front bottom slot');
        cube.executeSequence('F2');
        print('Executed F2');
      } else {
        String undoMove = '';
        if (matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF)) {
          print('Piece in right bottom slot, rotating y\'');
          cube.rotateCubeYPrime();
          _printAllEdges(cube, cD, cF, 'After y\' setup');
          undoMove = 'y';
        } else if (matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF)) {
          print('Piece in back bottom slot, rotating y2');
          cube.rotateCubeY();
          cube.rotateCubeY();
          _printAllEdges(cube, cD, cF, 'After y2 setup');
          undoMove = 'y2';
        } else if (matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) {
          print('Piece in left bottom slot, rotating y');
          cube.rotateCubeY();
          _printAllEdges(cube, cD, cF, 'After y setup');
          undoMove = 'y\'';
        }
        cube.executeSequence('F2');
        print('Executed F2 after setup');
        _printAllEdges(cube, cD, cF, 'After F2 extraction');
        if (undoMove == 'y') {
          cube.rotateCubeY();
          print('Restored orientation with y');
        } else if (undoMove == 'y2') {
          cube.rotateCubeY();
          cube.rotateCubeY();
          print('Restored orientation with y2');
        } else if (undoMove == 'y\'') {
          cube.rotateCubeYPrime();
          print('Restored orientation with y\'');
        }
      }
    } else {
      print('Piece not in bottom layer');
    }

    _printEdgePositions(cube, cD, cF);
    _printAllEdges(cube, cD, cF, 'After bottom-layer handling');

    bool pieceFound = false;
    for (int uRot = 0; uRot < 4 && !pieceFound; uRot++) {
      if (matchEdge(cube, Face.U, 2, 1, Face.F, 0, 1, cD, cF)) {
        pieceFound = true;
        print('Found piece at UF after $uRot U rotations');
        break;
      }
      cube.executeSequence('U');
      print('Rotated U');
    }

    if (!pieceFound) {
      print('Piece not found at UF; checking middle layer');
      if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cD, cF)) {
        print('Piece in FR middle slot; extracting with R U R\'');
        cube.executeSequence('R U R\'');
      } else if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 2, cD, cF)) {
        print('Piece in BR middle slot; extracting with R\' U R');
        cube.executeSequence('R\' U R');
      } else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 2, cD, cF)) {
        print('Piece in BL middle slot; extracting with L U L\'');
        cube.executeSequence('L U L\'');
      } else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cD, cF)) {
        print('Piece in FL middle slot; extracting with L\' U L');
        cube.executeSequence('L\' U L');
      } else {
        print('No piece found in the middle layer!');
      }

      _printEdgePositions(cube, cD, cF);
      for (int uRot = 0; uRot < 4; uRot++) {
        if (matchEdge(cube, Face.U, 2, 1, Face.F, 0, 1, cD, cF)) {
          print('Found piece at UF after extraction and $uRot U rotations');
          break;
        }
        cube.executeSequence('U');
        print('Rotated U');
      }
    }

    _printEdgePositions(cube, cD, cF);
    if (ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cD)) {
      print('Edge has D color on U face; using F2 insertion');
      cube.executeSequence('F2');
    } else {
      print('Edge has F color on U face; using U\' R\' F R insertion');
      cube.executeSequence("U' R' F R");
    }

    _printEdgePositions(cube, cD, cF);
    print('After insertion:');
    _printCrossState(cube, 'After insertion');

    cube.rotateCubeY();
    print('Rotated y at end of iteration');
  }
}

void _printEdgePositions(RubiksCube cube, Color cD, Color cF) {
  print('UF: U=${_colorValue(cube.grid[Face.U.index][2][1])}, F=${_colorValue(cube.grid[Face.F.index][0][1])}');
  print('UR: U=${_colorValue(cube.grid[Face.U.index][1][2])}, R=${_colorValue(cube.grid[Face.R.index][0][1])}');
  print('UB: U=${_colorValue(cube.grid[Face.U.index][0][1])}, B=${_colorValue(cube.grid[Face.B.index][0][1])}');
  print('UL: U=${_colorValue(cube.grid[Face.U.index][1][0])}, L=${_colorValue(cube.grid[Face.L.index][0][1])}');
  print('DF: D=${_colorValue(cube.grid[Face.D.index][0][1])}, F=${_colorValue(cube.grid[Face.F.index][2][1])}');
}

void _printAllEdges(RubiksCube cube, Color cD, Color cF, String label) {
  print('=== $label ===');
  print('UF: U=${_colorValue(cube.grid[Face.U.index][2][1])}, F=${_colorValue(cube.grid[Face.F.index][0][1])}');
  print('UR: U=${_colorValue(cube.grid[Face.U.index][1][2])}, R=${_colorValue(cube.grid[Face.R.index][0][1])}');
  print('UB: U=${_colorValue(cube.grid[Face.U.index][0][1])}, B=${_colorValue(cube.grid[Face.B.index][0][1])}');
  print('UL: U=${_colorValue(cube.grid[Face.U.index][1][0])}, L=${_colorValue(cube.grid[Face.L.index][0][1])}');
  print('DF: D=${_colorValue(cube.grid[Face.D.index][0][1])}, F=${_colorValue(cube.grid[Face.F.index][2][1])}');
  print('DR: D=${_colorValue(cube.grid[Face.D.index][1][2])}, R=${_colorValue(cube.grid[Face.R.index][2][1])}');
  print('DB: D=${_colorValue(cube.grid[Face.D.index][2][1])}, B=${_colorValue(cube.grid[Face.B.index][2][1])}');
  print('DL: D=${_colorValue(cube.grid[Face.D.index][1][0])}, L=${_colorValue(cube.grid[Face.L.index][2][1])}');
}

void _printCrossState(RubiksCube cube, String label) {
  print('=== $label ===');
  print('D edge: ${_colorValue(cube.grid[Face.D.index][0][1])}');
  print('F edge: ${_colorValue(cube.grid[Face.F.index][2][1])}');
  print('R edge: ${_colorValue(cube.grid[Face.R.index][2][1])}');
  print('B edge: ${_colorValue(cube.grid[Face.B.index][2][1])}');
  print('L edge: ${_colorValue(cube.grid[Face.L.index][2][1])}');
}

String _colorValue(Color color) => color.value.toRadixString(16).padLeft(8, '0');

List<List<List<Color>>> _createSolvedCube() {
  final colors = {
    Face.F: const Color(0xFF00FF00),
    Face.R: const Color(0xFFFF0000),
    Face.U: const Color(0xFFFFFFFF),
    Face.B: const Color(0xFF0000FF),
    Face.L: const Color(0xFFFFA500),
    Face.D: const Color(0xFFFFFF00),
  };

  return List.generate(6, (index) {
    final face = Face.values[index];
    return List.generate(3, (row) => List.generate(3, (col) => colors[face]!));
  });
}
