import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/cfop/f2l.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';

void main() {
  final cases = {
    'R U R\' U\'': "misoriented DFR",
    'R\'': "DBR",
    'D2': "DBL",
    'F': "DFL",
    'R2': "UBR",
    'R U2': "UBL",
    'F2': "UFL",
    "F'": "UF correct orientation",
    "F' U'": "UR correct orientation",
    'R2 B': "UB correct orientation",
    "F' U": "UL correct orientation",
    'R': "UR flipped",
    "R U'": "UB flipped",
    'R U2': "UL flipped",
    'R U': "UF flipped",
  };

  for (final entry in cases.entries) {
    final seq = entry.key;
    final cube = _createSolvedCube();
    final rubik = RubiksCube(cube);
    rubik.executeSequence(seq);
    try {
      final steps = solveF2L(rubik);
      final ok = _isF2LComplete(rubik);
      print('${entry.value} ($seq): steps=${steps.isEmpty ? 'empty' : steps} ok=$ok');
    } catch (e, st) {
      print('${entry.value} ($seq): EXCEPTION $e');
    }
  }
}

bool _isF2LComplete(RubiksCube cube) {
  final bottomCenter = cube.getCenterColor(Face.D);
  final frontCenter = cube.getCenterColor(Face.F);
  final rightCenter = cube.getCenterColor(Face.R);
  final backCenter = cube.getCenterColor(Face.B);
  final leftCenter = cube.getCenterColor(Face.L);

  final bottomCornersCorrect =
      cube.grid[Face.D.index][0][2] == bottomCenter &&
      cube.grid[Face.F.index][2][2] == frontCenter &&
      cube.grid[Face.R.index][2][0] == rightCenter &&
      cube.grid[Face.D.index][2][2] == bottomCenter &&
      cube.grid[Face.R.index][2][2] == rightCenter &&
      cube.grid[Face.B.index][2][0] == backCenter &&
      cube.grid[Face.D.index][2][0] == bottomCenter &&
      cube.grid[Face.B.index][2][2] == backCenter &&
      cube.grid[Face.L.index][2][0] == leftCenter &&
      cube.grid[Face.D.index][0][0] == bottomCenter &&
      cube.grid[Face.L.index][2][2] == leftCenter &&
      cube.grid[Face.F.index][2][0] == frontCenter;

  final middleEdgesCorrect =
      cube.grid[Face.F.index][1][2] == frontCenter &&
      cube.grid[Face.R.index][1][0] == rightCenter &&
      cube.grid[Face.R.index][1][2] == rightCenter &&
      cube.grid[Face.B.index][1][0] == backCenter &&
      cube.grid[Face.B.index][1][2] == backCenter &&
      cube.grid[Face.L.index][1][0] == leftCenter &&
      cube.grid[Face.L.index][1][2] == leftCenter &&
      cube.grid[Face.F.index][1][0] == frontCenter;

  return bottomCornersCorrect && middleEdgesCorrect;
}

List<List<List<Color>>> _createSolvedCube() {
  final colors = {
    Face.F: Colors.green,
    Face.R: Colors.red,
    Face.U: Colors.white,
    Face.B: Colors.blue,
    Face.L: Colors.orange,
    Face.D: Colors.yellow,
  };

  return List.generate(6, (index) {
    final face = Face.values[index];
    return List.generate(3, (row) => List.generate(3, (col) => colors[face]!));
  });
}
