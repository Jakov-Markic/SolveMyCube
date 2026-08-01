import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/f2l.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F2L solver fully completes supported starting positions', () {
    test('solves the misoriented DFR start position', () {
      final cube = _cubeFromSequence("R U R' U'");
      _assertF2LCompletes(cube);
    });

    test('solves the UFL start position', () {
      final cube = _cubeFromSequence('F2');
      _assertF2LCompletes(cube);
    });
  });

  group('F2L solver documented branch sequences', () {
    final cases = {
      'DBR start position': "R'",
      'DBL start position': 'D2',
      'DFL start position': 'F',
      'UBR start position': 'R2',
      'UBL start position': 'R U2',
      'UF correct edge orientation': "F'",
      'UR correct edge orientation': "F' U'",
      'UB correct edge orientation': 'R2 B',
      'UL correct edge orientation': "F' U",
      'UR flipped edge orientation': 'R',
      'UB flipped edge orientation': "R U'",
      'UL flipped edge orientation': 'R U2',
      'UF flipped edge orientation': 'R U',
    };

    cases.forEach((description, sequence) {
      test('returns a step sequence for $description', () {
        final cube = _cubeFromSequence(sequence);
        final steps = solveF2L(cube);

        expect(steps, isNotNull);
        expect(steps.trim(), isNotEmpty);
      });
    });
  });
}

RubiksCube _cubeFromSequence(String sequence) {
  final cube = RubiksCube(_createSolvedCube());
  cube.executeSequence(sequence);
  return cube;
}

void _assertF2LCompletes(RubiksCube cube) {
  final steps = solveF2L(cube);
  expect(steps, isNotEmpty);
  expect(_isF2LComplete(cube), isTrue);
}

bool _isF2LComplete(RubiksCube cube) {
  final bottomCenter = cube.getCenterColor(Face.D);
  final frontCenter = cube.getCenterColor(Face.F);
  final rightCenter = cube.getCenterColor(Face.R);
  final backCenter = cube.getCenterColor(Face.B);
  final leftCenter = cube.getCenterColor(Face.L);

  final bottomCornersCorrect =
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], frontCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], rightCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][2][2], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][2], rightCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.B.index][2][0], backCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][2][0], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.B.index][2][2], backCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.L.index][2][0], leftCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][0], bottomCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.L.index][2][2], leftCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][0], frontCenter);

  final middleEdgesCorrect =
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][1][2], frontCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][1][0], rightCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][1][2], rightCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.B.index][1][0], backCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.B.index][1][2], backCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.L.index][1][0], leftCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.L.index][1][2], leftCenter) &&
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][1][0], frontCenter);

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
