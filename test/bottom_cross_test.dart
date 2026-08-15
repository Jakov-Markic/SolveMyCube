import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/cfop/cfop.dart';

import 'test_helpers.dart';

void main() {
  group('solveBottomCross', () {
    test('leaves an already-solved cross untouched', () {
      final cube = RubiksCube(createSolvedCube());

      solveBottomCross(cube);

      expect(cube.checkBottomCross(), isTrue);
    });

    test('solves a lightly scrambled cross', () {
      final cube = cubeFromSequence('F B');

      expect(cube.checkBottomCross(), isFalse);

      final steps = solveBottomCross(cube);

      expect(steps, isNotEmpty);
      expect(cube.checkBottomCross(), isTrue);
    });

    test('solves every edge starting from each of the 4 middle-layer slots', () {
      // Scrambles chosen so a cross edge lands in the FR, BR, BL and FL
      // middle-layer slots respectively (regression coverage for the
      // matchEdge column-index bug in the RB/BL slot checks).
      for (final scramble in ["R U R' U'", "R' U' R U B", "B' U' B U L", "L' U' L U F"]) {
        final cube = cubeFromSequence(scramble);

        solveBottomCross(cube);

        expect(cube.checkBottomCross(), isTrue, reason: 'scramble "$scramble" should still solve the cross');
      }
    });

    test('regression: edge parked in the BR/BL middle slot is detected and solved', () {
      // This exact scramble left the DR-color edge sitting in the BR slot,
      // which the old (buggy) column indices never matched, corrupting the cross.
      final cube = cubeFromSequence(
        "U R' L U2 F' U' L' D' L U L B2 L2 F2 D L2 U' R2 F R2 D2 F U",
      );

      solveBottomCross(cube);

      expect(cube.checkBottomCross(), isTrue);
    });

    test('regression: aligning from UR/UL top-layer positions routes to the correct front slot', () {
      // This exact scramble required aligning a piece sitting at UR, which the
      // old (buggy) alignTop directions sent to UB instead of UF.
      final cube = cubeFromSequence(
        "F' L F' D' L' D L D L L' L2 L' R2 B' R2 F F2 D2 R' F2 R' U U2 U' U2",
      );

      solveBottomCross(cube);

      expect(cube.checkBottomCross(), isTrue);
    });

    test('solves the cross across many random scrambles', () {
      final rng = Random(1);
      for (int i = 0; i < 200; i++) {
        final cube = RubiksCube(createSolvedCube());
        final scramble = randomScramble(rng);
        cube.executeSequence(scramble);

        solveBottomCross(cube);

        expect(
          cube.checkBottomCross(),
          isTrue,
          reason: 'scramble "$scramble" (iteration $i) should leave the cross solved',
        );
      }
    });
  });
}
