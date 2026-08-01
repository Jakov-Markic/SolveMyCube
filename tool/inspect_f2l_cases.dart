import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

void main() {
  final cube = RubiksCube(_createSolvedCube());
  final seqs = {
    'R U R\' U\'': 'DFR misoriented from solved',
    'B\' U B': 'DBL or DBR? maybe',
    'L\' U L': 'DFL maybe',
    'U': 'UBR -> UFR align',
    'U2': 'UBL -> UFR align',
    'U\'': 'UFL -> UFR align',
  };
  for (final entry in seqs.entries) {
    final cube2 = RubiksCube(_createSolvedCube());
    cube2.executeSequence(entry.key);
    print('=== ${entry.value} (${entry.key}) ===');
    print('DFR: ${_cornerColors(cube2, Face.D,0,2, Face.F,2,2, Face.R,2,0)}');
    print('DBR: ${_cornerColors(cube2, Face.D,2,2, Face.R,2,2, Face.B,2,0)}');
    print('DBL: ${_cornerColors(cube2, Face.D,2,0, Face.B,2,2, Face.L,2,0)}');
    print('DFL: ${_cornerColors(cube2, Face.D,0,0, Face.L,2,2, Face.F,2,0)}');
    print('UFR: ${_cornerColors(cube2, Face.U,0,2, Face.R,0,2, Face.B,0,0)}');
    print('UBL: ${_cornerColors(cube2, Face.U,0,0, Face.B,0,2, Face.L,0,0)}');
    print('UFL: ${_cornerColors(cube2, Face.U,2,0, Face.L,0,2, Face.F,0,0)}');
  }
}

String _colorName(Color c) {
  if (ColorUtils.areColorsEqual(c, const Color(0xFFFFFF00))) return 'D';
  if (ColorUtils.areColorsEqual(c, const Color(0xFF00FF00))) return 'F';
  if (ColorUtils.areColorsEqual(c, const Color(0xFFFF0000))) return 'R';
  if (ColorUtils.areColorsEqual(c, const Color(0xFF0000FF))) return 'B';
  if (ColorUtils.areColorsEqual(c, const Color(0xFFFFA500))) return 'L';
  if (ColorUtils.areColorsEqual(c, const Color(0xFFFFFFFF))) return 'U';
  return '?';
}

String _cornerColors(RubiksCube cube, Face f1, int r1, int c1, Face f2, int r2, int c2, Face f3, int r3, int c3) {
  return '${_colorName(cube.grid[f1.index][r1][c1])}${_colorName(cube.grid[f2.index][r2][c2])}${_colorName(cube.grid[f3.index][r3][c3])}';
}

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
