import 'package:solve_my_cube/algorithms/rubik_cube.dart';
import 'package:solve_my_cube/color_utils.dart';

const maxDepth = 5;
const moves = ['U','U\'','U2','D','D\'','D2','R','R\'','R2','L','L\'','L2','F','F\'','F2','B','B\'','B2'];

bool matchTargetCorner(RubiksCube cube, Face f1, int r1, int c1, Face f2, int r2, int c2, Face f3, int r3, int c3) {
  final cD = cube.getCenterColor(Face.D);
  final cF = cube.getCenterColor(Face.F);
  final cR = cube.getCenterColor(Face.R);
  return matchCorner(cube, f1, r1, c1, f2, r2, c2, f3, r3, c3, cD, cF, cR);
}

void main() {
  final initial = RubiksCube(_createSolvedCube());
  for (var target in [
    ['DBR', Face.D,2,2, Face.R,2,2, Face.B,2,0],
    ['DBL', Face.D,2,0, Face.B,2,2, Face.L,2,0],
    ['DFL', Face.D,0,0, Face.L,2,2, Face.F,2,0],
    ['UBR', Face.U,0,2, Face.R,0,2, Face.B,0,0],
    ['UBL', Face.U,0,0, Face.B,0,2, Face.L,0,0],
    ['UFL', Face.U,2,0, Face.L,0,2, Face.F,0,0],
  ]) {
    final label = target[0] as String;
    final f1 = target[1] as Face;
    final r1 = target[2] as int;
    final c1 = target[3] as int;
    final f2 = target[4] as Face;
    final r2 = target[5] as int;
    final c2 = target[6] as int;
    final f3 = target[7] as Face;
    final r3 = target[8] as int;
    final c3 = target[9] as int;

    final seq = bfs(initial, f1,r1,c1,f2,r2,c2,f3,r3,c3);
    print('$label -> $seq');
  }
}

String bfs(RubiksCube start, Face f1, int r1, int c1, Face f2, int r2, int c2, Face f3, int r3, int c3) {
  final seen = <String>{};
  final queue = <List<String>>[['']];
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final state = RubiksCube(_createSolvedCube());
    for (final move in path) {
      if (move.isNotEmpty) state.executeSequence(move);
    }
    final key = state.grid.map((face) => face.expand((row) => row).map((c)=>c.value).join(',')).join('|');
    if (seen.contains(key)) continue;
    seen.add(key);
    if (matchTargetCorner(state, f1,r1,c1,f2,r2,c2,f3,r3,c3)) {
      return path.join(' ');
    }
    if (path.length >= maxDepth) continue;
    for (final move in moves) {
      queue.add([...path, move]);
    }
  }
  return 'NOT FOUND';
}

List<List<List<Color>>> _createSolvedCube() {
  final colors = {
    Face.F: Color(0xFF00FF00),
    Face.R: Color(0xFFFF0000),
    Face.U: Color(0xFFFFFFFF),
    Face.B: Color(0xFF0000FF),
    Face.L: Color(0xFFFFA500),
    Face.D: Color(0xFFFFFF00),
  };
  return List.generate(6, (index) {
    final face = Face.values[index];
    return List.generate(3, (row) => List.generate(3, (col) => colors[face]!));
  });
}
