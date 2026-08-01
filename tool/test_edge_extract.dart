import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

void main() {
  final scramble = "L' U2 R' U' B2 R' L D";
  final cube = RubiksCube(_createSolvedCube());
  cube.executeSequence(scramble);

  final cD = cube.getCenterColor(Face.D);
  final cF = cube.getCenterColor(Face.F);

  final candidates = [
    'F2',
    'F U R U\' R\' F\'',
    'F\' U\' F',
    'R U R\' U\' F\' U\' F',
    'R U R\' U\' R U R\' U\'',
    'L\' U\' L U F U F\'',
  ];

  for (final seq in candidates) {
    final testCube = RubiksCube(_cloneCube(cube.grid));
    testCube.executeSequence(seq);
    print('Sequence: $seq');
    print(_edgeStatus(testCube, cD, cF));
    print('-----');
  }
}

String _edgeStatus(RubiksCube cube, Color cD, Color cF) {
  final sb = StringBuffer();
  for (final pos in [
    ['UF', Face.U, 2, 1, Face.F, 0, 1],
    ['UR', Face.U, 1, 2, Face.R, 0, 1],
    ['UB', Face.U, 0, 1, Face.B, 0, 1],
    ['UL', Face.U, 1, 0, Face.L, 0, 1],
    ['DF', Face.D, 0, 1, Face.F, 2, 1],
    ['DR', Face.D, 1, 2, Face.R, 2, 1],
    ['DB', Face.D, 2, 1, Face.B, 2, 1],
    ['DL', Face.D, 1, 0, Face.L, 2, 1],
  ]) {
    final tag = pos[0];
    final u = cube.grid[(pos[1] as Face).index][pos[2] as int][pos[3] as int];
    final v = cube.grid[(pos[4] as Face).index][pos[5] as int][pos[6] as int];
    final match = (ColorUtils.areColorsEqual(u, cD) && ColorUtils.areColorsEqual(v, cF)) ||
        (ColorUtils.areColorsEqual(u, cF) && ColorUtils.areColorsEqual(v, cD));
    if (match) sb.writeln('$tag: U=${_colorValue(u)} F=${_colorValue(v)}');
  }
  return sb.toString();
}

String _colorValue(Color c) => c.value.toRadixString(16).padLeft(8,'0');

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

List<List<List<Color>>> _cloneCube(List<List<List<Color>>> grid) {
  return grid.map((face) => face.map((row) => row.toList()).toList()).toList();
}
