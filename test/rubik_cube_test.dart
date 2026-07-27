import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solve_my_cube/algorithms/cfop/ool.dart';
import 'package:solve_my_cube/algorithms/cfop/pll.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';

void main() {
  test('applyMove updates the cube state for a simple face turn', () {
    final cube = RubiksCube(_createDistinctCube());
    final originalFrontTopLeft = cube.grid[Face.F.index][0][0];
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

  test('PLL resolver treats a rotated solved cube as resolved', () {
    final cube = RubiksCube(_createSolvedCube());
    cube.rotateCubeY();

    expect(getPLLSignature(cube), '000111222333');
    expect(isPLLResolved(cube, cube.getCenterColor(Face.U)), isTrue);
  });

  test('OLL signature builder matches a known database key', () {
    final cube = RubiksCube(_createCubeFromOLLSignature('000010000010111010111'));
    expect(getOLLSignature(cube, Colors.white), '000010000010111010111');
  });
}

List<List<List<Color>>> _createDistinctCube() {
  final faces = List.generate(
    6,
    (index) => List.generate(
      3,
      (row) => List.generate(3, (col) => Color(0xFF000000 + (index * 0x010101) + (row * 0x000100) + col)),
    ),
  );

  return faces;
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

List<List<List<Color>>> _createCubeFromOLLSignature(String signature) {
  const targetColor = Colors.white;
  const otherColor = Colors.green;
  final faceColors = {
    Face.F: Colors.green,
    Face.R: Colors.red,
    Face.U: targetColor,
    Face.B: Colors.blue,
    Face.L: Colors.orange,
    Face.D: Colors.yellow,
  };

  final faces = <List<List<Color>>>[];
  for (final face in Face.values) {
    final faceGrid = List.generate(3, (row) => List.generate(3, (col) => faceColors[face]!));
    faces.add(faceGrid);
  }

  final bits = signature.split('');
  int index = 0;
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < 3; c++) {
      faces[Face.U.index][r][c] = bits[index] == '1' ? targetColor : otherColor;
      index++;
    }
  }

  for (final face in [Face.F, Face.R, Face.B, Face.L]) {
    for (int c = 0; c < 3; c++) {
      faces[face.index][0][c] = bits[index] == '1' ? targetColor : otherColor;
      index++;
    }
  }

  return faces;
}
