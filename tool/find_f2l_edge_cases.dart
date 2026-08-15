import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

const maxDepth = 6;
const moves = ['U','U\'','U2','R','R\'','R2','L','L\'','L2','F','F\'','F2','B','B\'','B2','D','D\'','D2'];

void main() {
  final initial = RubiksCube(_createSolvedCube());
  final targets = {
    'corner DBR': (RubiksCube cube) => matchCorner(cube, Face.D, 2, 2, Face.R, 2, 2, Face.B, 2, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'corner DBL': (RubiksCube cube) => matchCorner(cube, Face.D, 2, 0, Face.B, 2, 2, Face.L, 2, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'corner DFL': (RubiksCube cube) => matchCorner(cube, Face.D, 0, 0, Face.L, 2, 2, Face.F, 2, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'corner UBR': (RubiksCube cube) => matchCorner(cube, Face.U, 0, 2, Face.R, 0, 2, Face.B, 0, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'corner UBL': (RubiksCube cube) => matchCorner(cube, Face.U, 0, 0, Face.B, 0, 2, Face.L, 0, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'corner UFL': (RubiksCube cube) => matchCorner(cube, Face.U, 2, 0, Face.L, 0, 2, Face.F, 0, 0, cube.getCenterColor(Face.D), cube.getCenterColor(Face.F), cube.getCenterColor(Face.R)),
    'edge UF correct': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cube.getCenterColor(Face.F)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cube.getCenterColor(Face.R)),
    'edge UR correct': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cube.getCenterColor(Face.F)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cube.getCenterColor(Face.R)),
    'edge UB correct': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cube.getCenterColor(Face.F)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cube.getCenterColor(Face.R)),
    'edge UL correct': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cube.getCenterColor(Face.F)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cube.getCenterColor(Face.R)),
    'edge UR flipped': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cube.getCenterColor(Face.R)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cube.getCenterColor(Face.F)),
    'edge UB flipped': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cube.getCenterColor(Face.R)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cube.getCenterColor(Face.F)),
    'edge UL flipped': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cube.getCenterColor(Face.R)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cube.getCenterColor(Face.F)),
    'edge UF flipped': (RubiksCube cube) => ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cube.getCenterColor(Face.R)) && ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cube.getCenterColor(Face.F)),
  };

  for (final entry in targets.entries) {
    print('Searching for ${entry.key}...');
    final seq = bfs(initial, entry.value);
    print('${entry.key}: $seq');
  }
}

String bfs(RubiksCube start, bool Function(RubiksCube) predicate) {
  final seen = <String>{};
  final queue = <List<String>>[['']];
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final cube = RubiksCube(_createSolvedCube());
    for (final move in path) {
      if (move.isNotEmpty) cube.executeSequence(move);
    }
    final key = cube.grid.map((face) => face.expand((row) => row).map((c)=>c.value).join(',')).join('|');
    if (seen.contains(key)) continue;
    seen.add(key);
    if (predicate(cube)) {
      return path.where((m) => m.isNotEmpty).join(' ');
    }
    if (path.length >= maxDepth) continue;
    for (final move in moves) {
      queue.add([...path, move]);
    }
  }
  return 'NOT FOUND';
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
