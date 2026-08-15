import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

void main() {
  final moves = ['U','U\'','U2','R','R\'','R2','L','L\'','L2','F','F\'','F2','B','B\'','B2','D','D\'','D2'];
  final random = Random(123);

  for (int i = 0; i < 20000; i++) {
    final seq = List.generate(8, (_) => moves[random.nextInt(moves.length)]);
    final cube = RubiksCube(_createSolvedCube());
    cube.executeSequence(seq.join(' '));

    if (_isBottomCrossSolved(cube)) continue;

    final testCube = RubiksCube(_cloneCube(cube.grid));
    try {
      solveBottomCross(testCube);
      if (!_isBottomCrossSolved(testCube)) {
        print('FAIL scramble: ${seq.join(' ')}');
        return;
      }
    } catch (e, st) {
      print('EXCEPTION for scramble ${seq.join(' ')}: $e');
      return;
    }
  }

  print('No failure found after 20000 random scrambles.');
}

bool _isBottomCrossSolved(RubiksCube cube) {
  final bottomCenter = cube.getCenterColor(Face.D);
  final frontCenter = cube.getCenterColor(Face.F);
  final rightCenter = cube.getCenterColor(Face.R);
  final backCenter = cube.getCenterColor(Face.B);
  final leftCenter = cube.getCenterColor(Face.L);

  final edgesMatchBottom =
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][1], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][1][0], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][1][2], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][2][1], bottomCenter);

  final edgesMatchSides =
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][1], frontCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][1], rightCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.B.index][2][1], backCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.L.index][2][1], leftCenter);

  return edgesMatchBottom && edgesMatchSides;
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

List<List<List<Color>>> _cloneCube(List<List<List<Color>>> grid) {
  return grid.map((face) => face.map((row) => row.toList()).toList()).toList();
}
