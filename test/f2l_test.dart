import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/cfop/cfop.dart';
import 'package:solve_my_cube/algorithms/cfop/f2l.dart';

import 'test_helpers.dart';

void main() {
  group('solveF2L', () {
    test('leaves an already-solved F2L untouched', () {
      final cube = RubiksCube(createSolvedCube());

      solveF2L(cube);

      expect(cube.checkF2L(), isTrue);
    });

    test('solves the misoriented DFR start position', () {
      final cube = cubeFromSequence("R U R' U'");
      if (!cube.checkBottomCross()) solveBottomCross(cube);
      _assertF2LCompletes(cube);
    });

    test('solves the UFL start position', () {
      final cube = cubeFromSequence('F2');
      if (!cube.checkBottomCross()) solveBottomCross(cube);
      _assertF2LCompletes(cube);
    });

    group('completes for every documented single-slot starting position', () {
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
        test('solves the $description', () {
          final cube = cubeFromSequence(sequence);
          // solveF2L is only ever invoked after the cross is solved (see
          // solveCfop in cfop.dart); restore that precondition here since
          // these single/double-move scrambles otherwise leave it broken.
          if (!cube.checkBottomCross()) solveBottomCross(cube);
          _assertF2LCompletes(cube);
        });
      });
    });

    test('regression: edge parked in BR/BL/FL slot no longer corrupts an already-placed corner', () {
      // This exact scramble used to leave the DBL corner destroyed by the old
      // (buggy) BL-slot edge-extraction algorithm, which ran after all 4
      // corners were already placed.
      final cube = cubeFromSequence(
        "B' L2 R' B' D B D2 U F L' R2 R2 B2 D2 R U2 B' U' U2 D D2 U D' L2 B",
      );
      if (!cube.checkBottomCross()) solveBottomCross(cube);

      solveF2L(cube);

      expect(cube.checkF2L(), isTrue);
    });

    test('solves F2L across many random scrambles (cross solved first)', () {
      final rng = Random(2);
      for (int i = 0; i < 200; i++) {
        final cube = RubiksCube(createSolvedCube());
        final scramble = randomScramble(rng);
        cube.executeSequence(scramble);

        if (!cube.checkBottomCross()) solveBottomCross(cube);
        if (!cube.checkBottomCross()) {
          // Cross correctness is covered by bottom_cross_test.dart; skip here
          // rather than double-asserting an unrelated stage's behavior.
          continue;
        }

        solveF2L(cube);

        expect(
          cube.checkF2L(),
          isTrue,
          reason: 'scramble "$scramble" (iteration $i) should leave F2L solved',
        );
      }
    });
  });
}

void _assertF2LCompletes(RubiksCube cube) {
  solveF2L(cube);
  expect(cube.checkF2L(), isTrue);
}
