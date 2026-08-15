import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/cfop/cfop.dart';
import 'package:solve_my_cube/algorithms/cfop/f2l.dart';
import 'package:solve_my_cube/algorithms/cfop/oll.dart';
import 'package:solve_my_cube/algorithms/cfop/pll.dart';

import 'test_helpers.dart';

void main() {
  group('solvePLL', () {
    test('resolves an already-solved (possibly rotated) cube via AUF alone', () {
      final cube = RubiksCube(createSolvedCube());
      cube.rotateCubeY();

      solvePLL(cube);

      expect(cube.checkPLL(), isTrue);
    });

    test('solves a known-good permutation case (T perm)', () {
      // Built from the stored T-perm algorithm's inverse, so it reproduces
      // exactly the state that algorithm is documented to solve.
      final cube = RubiksCube(createSolvedCube());
      cube.executeSequence("F R U' R' U R U R2 F' R U R U' R'"); // inverse of the stored T-perm

      solvePLL(cube);

      expect(cube.checkPLL(), isTrue);
    });

    group('regression: every stored PLL entry round-trips (signature matches what its algorithm solves)', () {
      // These 5 previously had broken database entries: Ga/Gc/Y (stored
      // under the non-standard name "W") had algorithm strings that didn't
      // preserve F2L/OLL, and Gb/Gd had correct algorithms but wrong
      // signature strings, so solvePLL could never find a match for them.
      // Each case here is built from that entry's own algorithm's inverse,
      // so it reproduces exactly the state the algorithm is documented to
      // solve.
      final cases = {
        'Ga': "D R' U' R D' U R2 U R' U R U' R U' R2", // inverse of Ga
        'Gb': "D' R2 U R' U R' U' R U' R2 D U' R' U R", // inverse of Gb
        'Gc': "D' R U R' D U' R2 U' R U' R' U R' U R2", // inverse of Gc
        'Gd': "D R2 U' R U' R U R' U R2 D' U R U' R'", // inverse of Gd
        'Y': "F R' F' R U R U' R' F R U' R' U R U R' F'", // inverse of Y
      };

      cases.forEach((label, setup) {
        test(label, () {
          final cube = RubiksCube(createSolvedCube());
          cube.executeSequence(setup);
          expect(cube.checkF2L(), isTrue, reason: 'setup should only scramble the last layer');

          solvePLL(cube);

          expect(cube.checkPLL(), isTrue);
        });
      });
    });

    test('completes the last layer once OLL is solved, across many random scrambles', () {
      final rng = Random(11);
      int solvedCases = 0;
      for (int i = 0; i < 150; i++) {
        final cube = RubiksCube(createSolvedCube());
        cube.executeSequence(randomScramble(rng));

        if (!cube.checkBottomCross()) solveBottomCross(cube);
        if (!cube.checkBottomCross()) continue;
        if (!cube.checkF2L()) solveF2L(cube);
        if (!cube.checkF2L()) continue;
        if (!cube.checkOLL()) solveOLL(cube);

        solvedCases++;
        solvePLL(cube);

        expect(cube.checkPLL(), isTrue, reason: 'iteration $i should end with the cube fully solved');
      }

      expect(solvedCases, greaterThan(100));
    });
  });
}
