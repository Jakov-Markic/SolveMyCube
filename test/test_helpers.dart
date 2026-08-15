import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';

/// All single-face quarter/half turns, for building random scrambles.
const List<String> kAllFaceMoves = [
  'U', "U'", 'U2',
  'D', "D'", 'D2',
  'F', "F'", 'F2',
  'B', "B'", 'B2',
  'R', "R'", 'R2',
  'L', "L'", 'L2',
];

/// Builds a solved cube using the same face->color mapping used throughout
/// the CFOP solver tests (F=green, R=red, U=white, B=blue, L=orange, D=yellow).
List<List<List<Color>>> createSolvedCube() {
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

/// Returns a solved [RubiksCube] with [sequence] applied.
RubiksCube cubeFromSequence(String sequence) {
  final cube = RubiksCube(createSolvedCube());
  cube.executeSequence(sequence);
  return cube;
}

/// Generates a random scramble of [length] quarter/half turns using [rng].
String randomScramble(Random rng, {int length = 25}) {
  return List.generate(length, (_) => kAllFaceMoves[rng.nextInt(kAllFaceMoves.length)]).join(' ');
}
