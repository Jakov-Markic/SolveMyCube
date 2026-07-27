import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/cfop/pll.dart';
import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

Map<String, Color> letterToColor = {
  'B': Colors.blue,
  'G': Colors.green,
  'Y': Colors.yellow,
  'O': Colors.orange,
  'W': Colors.white,
  'R': Colors.red,
};

List<List<List<Color>>> buildCube(String input) {
  final faces = ['F', 'R', 'U', 'B', 'L', 'D'];
  final tokens = input.split(RegExp(r'\s+'));
  final faceData = <String, List<String>>{};
  String? currentFace;

  for (final token in tokens) {
    if (token.endsWith('-')) {
      currentFace = token.substring(0, token.length - 1);
      faceData[currentFace] = <String>[];
    } else if (currentFace != null) {
      faceData[currentFace]!.add(token);
    }
  }

  final result = <List<List<Color>>>[];
  for (final faceName in faces) {
    final cells = faceData[faceName]!;
    final face = <List<Color>>[];
    for (int i = 0; i < 3; i++) {
      final row = <Color>[];
      for (int j = 0; j < 3; j++) {
        row.add(letterToColor[cells[i * 3 + j]]!);
      }
      face.add(row);
    }
    result.add(face);
  }
  return result;
}

void main() {
  final input = 'F - B B G B B Y B B Y R - W W W G W W G R R U - W W B O O B O O R B - O G G O G G B G G L - O Y Y O Y Y Y Y Y D - R R O R R W R R W';
  final cube = RubiksCube(buildCube(input));
  final signature = _getPLLSignature(cube);
  print('signature=$signature');
  print('inDb=${standardPLLAlgorithms.containsKey(signature)}');
  print('centers=${cube.getCenterColor(Face.F)} ${cube.getCenterColor(Face.R)} ${cube.getCenterColor(Face.U)} ${cube.getCenterColor(Face.B)} ${cube.getCenterColor(Face.L)} ${cube.getCenterColor(Face.D)}');
}

String _getPLLSignature(RubiksCube cube) {
  StringBuffer sig = StringBuffer();
  Color colorF = cube.getCenterColor(Face.F);
  Color colorR = cube.getCenterColor(Face.R);
  Color colorB = cube.getCenterColor(Face.B);
  Color colorL = cube.getCenterColor(Face.L);

  String getColorCode(Color color) {
    if (ColorUtils.areColorsEqual(color, colorF)) return '0';
    if (ColorUtils.areColorsEqual(color, colorR)) return '1';
    if (ColorUtils.areColorsEqual(color, colorB)) return '2';
    if (ColorUtils.areColorsEqual(color, colorL)) return '3';
    return '?';
  }

  final sideFaces = [Face.F, Face.R, Face.B, Face.L];
  for (var face in sideFaces) {
    for (int c = 0; c < 3; c++) {
      sig.write(getColorCode(cube.grid[face.index][0][c]));
    }
  }
  return sig.toString();
}
