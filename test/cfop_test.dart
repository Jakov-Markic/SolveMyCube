import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/cfop.dart';

import 'test_helpers.dart';

void main() {
  group('CfopRubiksCubeExtension stage checks', () {
    test('all four checks are true on a solved cube', () {
      final cube = RubiksCube(createSolvedCube());

      expect(cube.checkBottomCross(), isTrue);
      expect(cube.checkF2L(), isTrue);
      expect(cube.checkOLL(), isTrue);
      expect(cube.checkPLL(), isTrue);
    });

    test('all four checks are false once the cube is scrambled', () {
      final cube = cubeFromSequence("R U R' U' F2 B2 L' D");

      expect(cube.checkBottomCross(), isFalse);
      expect(cube.checkF2L(), isFalse);
      expect(cube.checkOLL(), isFalse);
      expect(cube.checkPLL(), isFalse);
    });

    test('checkBottomCross and checkF2L ignore a pure U-layer twist', () {
      // A single U turn only permutes the U face and the side faces' top
      // rows, so the cross, F2L and OLL (U-face-only) all still read as
      // solved; only PLL (which checks every side sticker) catches the twist.
      final cube = cubeFromSequence('U');

      expect(cube.checkBottomCross(), isTrue);
      expect(cube.checkF2L(), isTrue);
      expect(cube.checkOLL(), isTrue);
      expect(cube.checkPLL(), isFalse);
    });
  });

  group('optimizeAlgorithm', () {
    test('returns an empty string for empty input', () {
      expect(optimizeAlgorithm(''), '');
      expect(optimizeAlgorithm('   '), '');
    });

    test('combines three quarter turns of the same face into one inverse turn', () {
      expect(optimizeAlgorithm('U U U'), "U'");
    });

    test('cancels a turn immediately followed by its inverse', () {
      expect(optimizeAlgorithm("U U'"), '');
    });

    test('cancels two half turns of the same face', () {
      expect(optimizeAlgorithm('U2 U2'), '');
    });

    test('merges same-face turns across a commuting face in between', () {
      // L commutes with R (opposite faces), so the R ... R' pair should
      // merge through it, cancelling out and leaving only the L turn.
      expect(optimizeAlgorithm("R L R'"), 'L');
    });

    test('does not merge same-face turns across a non-commuting face', () {
      // F does not commute with R, so this sequence must be left untouched.
      expect(optimizeAlgorithm("R F R'"), "R F R'");
    });

    test('leaves an already-minimal sequence unchanged', () {
      expect(optimizeAlgorithm("R U R' U'"), "R U R' U'");
    });
  });

  group('solveCfop', () {
    test('fully solves a scrambled cube', () {
      final cube = RubiksCube(createSolvedCube());
      const scramble = "R U R' U'";
      cube.executeSequence(scramble);

      final solution = solveCfop(cube.grid);

      final verifyCube = RubiksCube(createSolvedCube());
      verifyCube.executeSequence(scramble);
      verifyCube.executeSequence(solution);

      expect(verifyCube.checkPLL(), isTrue);
    });

    test('returns an empty solution for an already-solved cube', () {
      final cube = RubiksCube(createSolvedCube());

      final solution = solveCfop(cube.grid);

      expect(solution, isEmpty);
    });
  });
}
