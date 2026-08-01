import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('solveBottomCross solves the bottom cross correctly', () {
    final cube = RubiksCube(_createSolvedCube());

    // Scramble the cube just enough to break the bottom cross.
    cube.executeSequence('F B');

    expect(_isBottomCrossSolved(cube), isFalse);

    final steps = solveBottomCross(cube);

    expect(steps, isNotEmpty);
    expect(_isBottomCrossSolved(cube), isTrue);
  });
}

bool _isBottomCrossSolved(RubiksCube cube) {
  final bottomCenter = cube.getCenterColor(Face.D);
  final frontCenter = cube.getCenterColor(Face.F);
  final rightCenter = cube.getCenterColor(Face.R);
  final backCenter = cube.getCenterColor(Face.B);
  final leftCenter = cube.getCenterColor(Face.L);

  final edgesMatchBottom =
      cube.grid[Face.D.index][0][1] == bottomCenter &&
      cube.grid[Face.D.index][1][0] == bottomCenter &&
      cube.grid[Face.D.index][1][2] == bottomCenter &&
      cube.grid[Face.D.index][2][1] == bottomCenter;

  final edgesMatchSides =
      cube.grid[Face.F.index][2][1] == frontCenter &&
      cube.grid[Face.R.index][2][1] == rightCenter &&
      cube.grid[Face.B.index][2][1] == backCenter &&
      cube.grid[Face.L.index][2][1] == leftCenter;

  return edgesMatchBottom && edgesMatchSides;
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
