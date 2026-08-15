import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';

import 'test_helpers.dart';

void main() {
  group('RubiksCube move engine', () {
    test('applyMove updates the cube state for a simple face turn', () {
      final cube = RubiksCube(_createDistinctCube());
      final originalRightTopLeft = cube.grid[Face.R.index][0][0];

      cube.applyMove(Move.U);

      expect(cube.grid[Face.F.index][0][0], originalRightTopLeft);
      expect(cube.grid[Face.R.index][0][0], isNot(originalRightTopLeft));
    });

    test('executeSequence parses and applies moves', () {
      final cube = RubiksCube(_createDistinctCube());
      final originalRightTopLeft = cube.grid[Face.R.index][0][0];

      cube.executeSequence('U');

      expect(cube.grid[Face.F.index][0][0], originalRightTopLeft);
    });

    test('four quarter turns of any face return the cube to solved', () {
      for (final face in ['U', 'D', 'F', 'B', 'R', 'L']) {
        final cube = RubiksCube(createSolvedCube());
        cube.executeSequence('$face $face $face $face');
        expect(cube.grid, createSolvedCube(), reason: '4x $face should return to solved');
      }
    });

    test('a move immediately followed by its inverse cancels out', () {
      for (final face in ['U', 'D', 'F', 'B', 'R', 'L']) {
        final cube = RubiksCube(createSolvedCube());
        cube.executeSequence("$face $face'");
        expect(cube.grid, createSolvedCube(), reason: "$face $face' should cancel out");
      }
    });

    test('four y rotations return the cube to its original state', () {
      final cube = RubiksCube(_createDistinctCube());
      final original = cube.clone().grid;

      cube.rotateCubeY();
      cube.rotateCubeY();
      cube.rotateCubeY();
      cube.rotateCubeY();

      expect(cube.grid, original);
    });

    test('U D-prime matches a whole-cube y rotation on the U/D layers', () {
      // A well-known cubing identity (y = U D'); this pins down that U and D
      // turn in opposite rotational senses, matching standard notation.
      final combo = RubiksCube(createSolvedCube());
      combo.executeSequence("U D'");

      final rotated = RubiksCube(createSolvedCube());
      rotated.rotateCubeY();

      expect(combo.grid[Face.U.index], rotated.grid[Face.U.index]);
      expect(combo.grid[Face.D.index], rotated.grid[Face.D.index]);
      for (final face in [Face.F, Face.R, Face.B, Face.L]) {
        expect(combo.grid[face.index][0], rotated.grid[face.index][0], reason: '${face.name} top row');
        expect(combo.grid[face.index][2], rotated.grid[face.index][2], reason: '${face.name} bottom row');
      }
    });
  });
}

List<List<List<Color>>> _createDistinctCube() {
  return List.generate(
    6,
    (index) => List.generate(
      3,
      (row) => List.generate(3, (col) => Color(0xFF000000 + (index * 0x010101) + (row * 0x000100) + col)),
    ),
  );
}
