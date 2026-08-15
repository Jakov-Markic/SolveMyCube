import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/cfop/cfop.dart';
import 'package:solve_my_cube/algorithms/cfop/f2l.dart';
import 'package:solve_my_cube/algorithms/cfop/oll.dart';

import 'test_helpers.dart';

void main() {
  group('solveOLL', () {
    test('returns no steps when the top face is already solved', () {
      final cube = RubiksCube(createSolvedCube());

      final steps = solveOLL(cube);

      expect(steps, isEmpty);
      expect(cube.checkOLL(), isTrue);
    });

    test('every stored signature has its U-face center reading as solved', () {
      // The 5th character of every OLL signature is the U face's own
      // center sticker, which always matches itself by definition -- so it
      // must always be "1". A "0" there means the signature was transcribed
      // wrong (this caught case 19's original entry).
      for (final signature in standardOLLAlgorithms.keys) {
        expect(
          signature[4],
          '1',
          reason: 'signature "$signature" has an invalid U-center reading',
        );
      }
    });

    group('regression: previously-broken database entries now solve', () {
      final cases = {
        // "M2'" is not a token the move parser recognizes (M half-turns are
        // self-inverse, so it should just be "M2"); the unrecognized token
        // was silently dropped, breaking the algorithm.
        'Dot 8 (the fixed "M2\' " token)': "r U R' U' M2 U R U' R' U' M'",
        // The signature's U-center bit was wrongly recorded as 0, and the
        // algorithm itself didn't preserve F2L; both signature and
        // algorithm were replaced with a verified-correct pair.
        'Dot 7 (the fixed signature and algorithm)': "F R' F' R M U R U' R' U' R' r",
      };

      cases.forEach((label, setup) {
        test(label, () {
          final cube = RubiksCube(createSolvedCube());
          cube.executeSequence(setup); // inverse of that case's algorithm

          solveOLL(cube);

          expect(cube.checkOLL(), isTrue);
        });
      });
    });

    test('orients the last layer once F2L is solved, across many random scrambles', () {
      final rng = Random(3);
      int solvedCases = 0;
      for (int i = 0; i < 150; i++) {
        final cube = RubiksCube(createSolvedCube());
        cube.executeSequence(randomScramble(rng));

        if (!cube.checkBottomCross()) solveBottomCross(cube);
        if (!cube.checkBottomCross()) continue;
        if (!cube.checkF2L()) solveF2L(cube);
        if (!cube.checkF2L()) continue;

        solvedCases++;
        if (!cube.checkOLL()) {
          solveOLL(cube);
        }

        expect(cube.checkOLL(), isTrue, reason: 'iteration $i should end with the top face oriented');
      }

      expect(solvedCases, greaterThan(100));
    });
  });
}
