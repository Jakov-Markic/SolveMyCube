import 'package:flutter/material.dart';
import '../rubik_cube.dart';

export 'kociemba.dart' show solveKociemba;

// Constants
class KociembaConstants {
  static const int N_CORNER = 8;
  static const int N_EDGE = 12;
  static const int N_MOVE = 18;
  
  static const List<String> MOVE_NAMES = [
    'U', 'U2', "U'",
    'D', 'D2', "D'",
    'R', 'R2', "R'",
    'L', 'L2', "L'",
    'F', 'F2', "F'",
    'B', 'B2', "B'"
  ];
  
  // Phase 2 moves: U, D, R2, L2, F2, B2
  static const List<int> PHASE2_MOVES = [0, 1, 2, 4, 6, 7, 8, 10, 12, 13, 14, 16];
}

// Kociemba Cube Representation
class KociembaCube {
  List<int> cornerPerm;
  List<int> cornerOrient;
  List<int> edgePerm;
  List<int> edgeOrient;
  
  KociembaCube({
    required this.cornerPerm,
    required this.cornerOrient,
    required this.edgePerm,
    required this.edgeOrient,
  });
  
  factory KociembaCube.solved() {
    return KociembaCube(
      cornerPerm: List.generate(8, (i) => i),
      cornerOrient: List.generate(8, (i) => 0),
      edgePerm: List.generate(12, (i) => i),
      edgeOrient: List.generate(12, (i) => 0),
    );
  }
  
  KociembaCube clone() {
    return KociembaCube(
      cornerPerm: List.from(cornerPerm),
      cornerOrient: List.from(cornerOrient),
      edgePerm: List.from(edgePerm),
      edgeOrient: List.from(edgeOrient),
    );
  }
  
  void applyMove(int move) {
    int face = move ~/ 3;
    int power = move % 3;
    
    if (power == 1) {
      _applyBasicMove(face, true);
      _applyBasicMove(face, true);
    } else if (power == 2) {
      _applyBasicMove(face, false);
    } else {
      _applyBasicMove(face, true);
    }
  }
  
  void _applyBasicMove(int face, bool clockwise) {
    switch(face) {
      case 0: clockwise ? _moveU() : _moveUPrime(); break;
      case 1: clockwise ? _moveD() : _moveDPrime(); break;
      case 2: clockwise ? _moveR() : _moveRPrime(); break;
      case 3: clockwise ? _moveL() : _moveLPrime(); break;
      case 4: clockwise ? _moveF() : _moveFPrime(); break;
      case 5: clockwise ? _moveB() : _moveBPrime(); break;
    }
  }
  
  void _moveU() {
    _rotateCorners([0, 1, 2, 3], [1, 2, 3, 0], [0, 0, 0, 0]);
    _rotateEdges([0, 1, 2, 3], [1, 2, 3, 0], [0, 0, 0, 0]);
  }
  
  void _moveUPrime() {
    _rotateCorners([0, 1, 2, 3], [3, 0, 1, 2], [0, 0, 0, 0]);
    _rotateEdges([0, 1, 2, 3], [3, 0, 1, 2], [0, 0, 0, 0]);
  }
  
  void _moveD() {
    _rotateCorners([4, 5, 6, 7], [5, 6, 7, 4], [0, 0, 0, 0]);
    _rotateEdges([4, 5, 6, 7], [5, 6, 7, 4], [0, 0, 0, 0]);
  }
  
  void _moveDPrime() {
    _rotateCorners([4, 5, 6, 7], [7, 4, 5, 6], [0, 0, 0, 0]);
    _rotateEdges([4, 5, 6, 7], [7, 4, 5, 6], [0, 0, 0, 0]);
  }
  
  void _moveR() {
    _rotateCorners([0, 3, 7, 4], [3, 7, 4, 0], [2, 1, 2, 1]);
    _rotateEdges([0, 9, 4, 11], [9, 4, 11, 0], [1, 1, 1, 1]);
  }
  
  void _moveRPrime() {
    _rotateCorners([0, 3, 7, 4], [4, 0, 3, 7], [1, 2, 1, 2]);
    _rotateEdges([0, 9, 4, 11], [11, 0, 9, 4], [1, 1, 1, 1]);
  }
  
  void _moveL() {
    _rotateCorners([1, 5, 6, 2], [5, 6, 2, 1], [2, 1, 2, 1]);
    _rotateEdges([2, 8, 6, 10], [8, 6, 10, 2], [1, 1, 1, 1]);
  }
  
  void _moveLPrime() {
    _rotateCorners([1, 5, 6, 2], [2, 1, 5, 6], [1, 2, 1, 2]);
    _rotateEdges([2, 8, 6, 10], [10, 2, 8, 6], [1, 1, 1, 1]);
  }
  
  void _moveF() {
    _rotateCorners([0, 1, 5, 4], [1, 5, 4, 0], [1, 2, 1, 2]);
    _rotateEdges([1, 8, 5, 9], [8, 5, 9, 1], [1, 1, 1, 1]);
  }
  
  void _moveFPrime() {
    _rotateCorners([0, 1, 5, 4], [4, 0, 1, 5], [2, 1, 2, 1]);
    _rotateEdges([1, 8, 5, 9], [9, 1, 8, 5], [1, 1, 1, 1]);
  }
  
  void _moveB() {
    _rotateCorners([2, 3, 7, 6], [3, 7, 6, 2], [1, 2, 1, 2]);
    _rotateEdges([3, 11, 7, 10], [11, 7, 10, 3], [1, 1, 1, 1]);
  }
  
  void _moveBPrime() {
    _rotateCorners([2, 3, 7, 6], [6, 2, 3, 7], [2, 1, 2, 1]);
    _rotateEdges([3, 11, 7, 10], [10, 3, 11, 7], [1, 1, 1, 1]);
  }
  
  void _rotateCorners(List<int> indices, List<int> permutation, List<int> orientationChanges) {
    List<int> oldPerm = List.from(cornerPerm);
    List<int> oldOrient = List.from(cornerOrient);
    
    for (int i = 0; i < indices.length; i++) {
      cornerPerm[indices[i]] = oldPerm[permutation[i]];
      cornerOrient[indices[i]] = (oldOrient[permutation[i]] + orientationChanges[i]) % 3;
    }
  }
  
  void _rotateEdges(List<int> indices, List<int> permutation, List<int> orientationChanges) {
    List<int> oldPerm = List.from(edgePerm);
    List<int> oldOrient = List.from(edgeOrient);
    
    for (int i = 0; i < indices.length; i++) {
      edgePerm[indices[i]] = oldPerm[permutation[i]];
      edgeOrient[indices[i]] = (oldOrient[permutation[i]] + orientationChanges[i]) % 2;
    }
  }
  
  bool isSolved() {
    for (int i = 0; i < 8; i++) {
      if (cornerPerm[i] != i || cornerOrient[i] != 0) return false;
    }
    for (int i = 0; i < 12; i++) {
      if (edgePerm[i] != i || edgeOrient[i] != 0) return false;
    }
    return true;
  }
  
  // Check if phase 1 is complete (all pieces oriented)
  bool isPhase1Complete() {
    for (int i = 0; i < 8; i++) {
      if (cornerOrient[i] != 0) return false;
    }
    for (int i = 0; i < 12; i++) {
      if (edgeOrient[i] != 0) return false;
    }
    return true;
  }
}

// Convert RubiksCube to KociembaCube
extension KociembaCubeConversion on RubiksCube {
  KociembaCube toKociembaCube() {
    // Map colors to indices (0-5)
    Map<Color, int> colorMap = {};
    List<Face> faces = [Face.U, Face.R, Face.F, Face.D, Face.L, Face.B];
    for (int i = 0; i < faces.length; i++) {
      colorMap[getCenterColor(faces[i])] = i;
    }
    
    KociembaCube cube = KociembaCube.solved();
    
    // Extract corners
    _extractCorner(cube, 0, Face.U, 0, 0, Face.F, 0, 2, Face.R, 0, 0, colorMap);
    _extractCorner(cube, 1, Face.U, 0, 2, Face.F, 0, 0, Face.L, 0, 2, colorMap);
    _extractCorner(cube, 2, Face.U, 2, 2, Face.L, 0, 0, Face.B, 0, 2, colorMap);
    _extractCorner(cube, 3, Face.U, 2, 0, Face.B, 0, 0, Face.R, 0, 2, colorMap);
    _extractCorner(cube, 4, Face.D, 0, 0, Face.F, 2, 2, Face.R, 2, 0, colorMap);
    _extractCorner(cube, 5, Face.D, 0, 2, Face.F, 2, 0, Face.L, 2, 2, colorMap);
    _extractCorner(cube, 6, Face.D, 2, 2, Face.L, 2, 0, Face.B, 2, 2, colorMap);
    _extractCorner(cube, 7, Face.D, 2, 0, Face.B, 2, 0, Face.R, 2, 2, colorMap);
    
    // Extract edges
    _extractEdge(cube, 0, Face.U, 0, 1, Face.R, 0, 1, colorMap);
    _extractEdge(cube, 1, Face.U, 1, 2, Face.F, 0, 1, colorMap);
    _extractEdge(cube, 2, Face.U, 2, 1, Face.L, 0, 1, colorMap);
    _extractEdge(cube, 3, Face.U, 1, 0, Face.B, 0, 1, colorMap);
    _extractEdge(cube, 4, Face.D, 0, 1, Face.R, 2, 1, colorMap);
    _extractEdge(cube, 5, Face.D, 1, 2, Face.F, 2, 1, colorMap);
    _extractEdge(cube, 6, Face.D, 2, 1, Face.L, 2, 1, colorMap);
    _extractEdge(cube, 7, Face.D, 1, 0, Face.B, 2, 1, colorMap);
    _extractEdge(cube, 8, Face.F, 1, 2, Face.R, 1, 0, colorMap);
    _extractEdge(cube, 9, Face.F, 1, 0, Face.L, 1, 2, colorMap);
    _extractEdge(cube, 10, Face.L, 1, 0, Face.B, 1, 2, colorMap);
    _extractEdge(cube, 11, Face.B, 1, 0, Face.R, 1, 2, colorMap);
    
    return cube;
  }
  
  void _extractCorner(KociembaCube cube, int index,
      Face f1, int r1, int c1, Face f2, int r2, int c2, Face f3, int r3, int c3,
      Map<Color, int> colorMap) {
    
    Color col1 = grid[f1.index][r1][c1];
    Color col2 = grid[f2.index][r2][c2];
    Color col3 = grid[f3.index][r3][c3];
    
    int idx1 = colorMap[col1]!;
    int idx2 = colorMap[col2]!;
    int idx3 = colorMap[col3]!;
    
    List<List<int>> cornerColors = [
      [0, 2, 1], // URF
      [0, 2, 4], // UFL
      [0, 4, 5], // ULB
      [0, 5, 1], // UBR
      [3, 2, 1], // DFR
      [3, 2, 4], // DLF
      [3, 4, 5], // DBL
      [3, 5, 1], // DRB
    ];
    
    for (int i = 0; i < 8; i++) {
      Set<int> target = {cornerColors[i][0], cornerColors[i][1], cornerColors[i][2]};
      Set<int> current = {idx1, idx2, idx3};
      
      if (target.containsAll(current) && current.containsAll(target)) {
        cube.cornerPerm[index] = i;
        
        int uColor = 0, dColor = 3;
        if (idx1 == uColor || idx1 == dColor) {
          cube.cornerOrient[index] = 0;
        } else if (idx2 == uColor || idx2 == dColor) {
          cube.cornerOrient[index] = 1;
        } else if (idx3 == uColor || idx3 == dColor) {
          cube.cornerOrient[index] = 2;
        }
        break;
      }
    }
  }
  
  void _extractEdge(KociembaCube cube, int index,
      Face f1, int r1, int c1, Face f2, int r2, int c2,
      Map<Color, int> colorMap) {
    
    Color col1 = grid[f1.index][r1][c1];
    Color col2 = grid[f2.index][r2][c2];
    
    int idx1 = colorMap[col1]!;
    int idx2 = colorMap[col2]!;
    
    List<List<int>> edgeColors = [
      [0, 1], // UR
      [0, 2], // UF
      [0, 4], // UL
      [0, 5], // UB
      [3, 1], // DR
      [3, 2], // DF
      [3, 4], // DL
      [3, 5], // DB
      [2, 1], // FR
      [2, 4], // FL
      [4, 5], // BL
      [5, 1], // BR
    ];
    
    for (int i = 0; i < 12; i++) {
      Set<int> target = {edgeColors[i][0], edgeColors[i][1]};
      Set<int> current = {idx1, idx2};
      
      if (target.containsAll(current) && current.containsAll(target)) {
        cube.edgePerm[index] = i;
        
        if (idx1 == 0 || idx1 == 3) {
          if (f1 == Face.U || f1 == Face.D) {
            cube.edgeOrient[index] = 0;
          } else {
            cube.edgeOrient[index] = 1;
          }
        } else if (idx2 == 0 || idx2 == 3) {
          if (f2 == Face.U || f2 == Face.D) {
            cube.edgeOrient[index] = 0;
          } else {
            cube.edgeOrient[index] = 1;
          }
        }
        break;
      }
    }
  }
}

// Two-Phase Kociemba Solver (Fixed)
class KociembaSolver {
  // Phase 1 max depth: orient all pieces
  static const int PHASE1_MAX_DEPTH = 12;
  
  // Phase 2 max depth: permute all pieces
  static const int PHASE2_MAX_DEPTH = 18;
  
  // Timeout in milliseconds
  static const int TIMEOUT_MS = 30000; // 30 seconds
  
  String solve(RubiksCube cube) {
    try {
      final stopwatch = Stopwatch()..start();
      KociembaCube kCube = cube.toKociembaCube();
      
      print("Starting Two-Phase Kociemba Solver...");
      
      // Check if already solved
      if (kCube.isSolved()) {
        return "";
      }
      
      // PHASE 1: Orient all pieces (use ALL moves)
      print("Phase 1: Orienting pieces...");
      List<String>? phase1Solution = _phase1Search(kCube);
      
      if (phase1Solution == null) {
        print("Phase 1 failed - no solution found. Trying direct solve...");
        // Fallback: try direct solve
        return _directSolve(kCube);
      }
      
      // Apply phase 1 solution
      for (String move in phase1Solution) {
        int moveIndex = _moveStringToIndex(move);
        kCube.applyMove(moveIndex);
      }
      
      print("Phase 1 complete: ${phase1Solution.length} moves, ${stopwatch.elapsedMilliseconds}ms");
      
      // Verify phase 1 is complete
      if (!kCube.isPhase1Complete()) {
        print("Phase 1 verification failed!");
        return '';
      }
      
      // PHASE 2: Permute all pieces
      print("Phase 2: Permuting pieces...");
      List<String>? phase2Solution = _phase2Search(kCube);
      
      if (phase2Solution == null) {
        print("Phase 2 failed - no solution found");
        return '';
      }
      
      print("Phase 2 complete: ${phase2Solution.length} moves, ${stopwatch.elapsedMilliseconds}ms");
      
      // Combine solutions
      List<String> fullSolution = [...phase1Solution, ...phase2Solution];
      print("Full solution found: ${fullSolution.length} moves in ${stopwatch.elapsedMilliseconds}ms");
      
      return fullSolution.join(' ');
    } catch (e, stack) {
      print('Kociemba error: $e');
      print('Stack trace: $stack');
      return '';
    }
  }
  
  // Fallback: direct solve if phase 1 fails
  String _directSolve(KociembaCube cube) {
    print("Attempting direct solve...");
    
    for (int depth = 1; depth <= 20; depth++) {
      print("  Direct search depth $depth...");
      
      final stopwatch = Stopwatch()..start();
      List<String>? result = _idaSearchDirect(cube, depth, [], -1);
      stopwatch.stop();
      
      if (result != null && result.isNotEmpty) {
        print("Direct solution found: ${result.length} moves");
        return result.join(' ');
      }
      
      if (stopwatch.elapsedMilliseconds > TIMEOUT_MS) {
        print("Direct search timeout at depth $depth");
        break;
      }
    }
    
    return '';
  }
  
  List<String>? _idaSearchDirect(KociembaCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (cube.isSolved()) {
        return path;
      }
      return null;
    }
    
    // Simple heuristic
    int misplaced = 0;
    for (int i = 0; i < 8; i++) {
      if (cube.cornerPerm[i] != i || cube.cornerOrient[i] != 0) misplaced++;
    }
    for (int i = 0; i < 12; i++) {
      if (cube.edgePerm[i] != i || cube.edgeOrient[i] != 0) misplaced++;
    }
    int heuristic = (misplaced + 2) ~/ 3;
    
    if (heuristic > depth) return null;
    
    // Try all moves
    for (int move = 0; move < KociembaConstants.N_MOVE; move++) {
      int face = move ~/ 3;
      
      if (face == lastFace) continue;
      if (lastFace >= 0) {
        if ((face == 0 && lastFace == 1) || (face == 1 && lastFace == 0)) continue;
        if ((face == 2 && lastFace == 3) || (face == 3 && lastFace == 2)) continue;
        if ((face == 4 && lastFace == 5) || (face == 5 && lastFace == 4)) continue;
      }
      
      KociembaCube newCube = cube.clone();
      newCube.applyMove(move);
      
      String moveStr = KociembaConstants.MOVE_NAMES[move];
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _idaSearchDirect(newCube, depth - 1, newPath, face);
      if (result != null) return result;
    }
    
    return null;
  }
  
  // PHASE 1: Orient all pieces (use ALL moves, not just R/L/F/B)
  List<String>? _phase1Search(KociembaCube cube) {
    // Check if phase 1 is already complete
    if (cube.isPhase1Complete()) {
      return [];
    }
    
    // Try increasing depths
    for (int depth = 1; depth <= PHASE1_MAX_DEPTH; depth++) {
      print("  Phase 1: searching depth $depth...");
      
      final stopwatch = Stopwatch()..start();
      List<String>? result = _idaSearchPhase1(cube, depth, [], -1);
      stopwatch.stop();
      
      if (result != null) {
        return result;
      }
      
      if (stopwatch.elapsedMilliseconds > TIMEOUT_MS) {
        print("  Phase 1 timeout at depth $depth");
        return null;
      }
    }
    
    return null;
  }
  
  List<String>? _idaSearchPhase1(KociembaCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (cube.isPhase1Complete()) {
        return path;
      }
      return null;
    }
    
    // Heuristic: count pieces that need orientation
    int oriented = _countOriented(cube);
    int heuristic = (20 - oriented + 3) ~/ 4;
    
    // More lenient heuristic
    if (heuristic > depth + 1) return null;
    
    // Try ALL moves (including U and D) in priority order
    List<int> moves = _getPhase1MovesAll(cube, lastFace);
    
    for (int move in moves) {
      int face = move ~/ 3;
      
      // Skip redundant moves
      if (face == lastFace) continue;
      
      // Skip opposite face moves (they cancel each other)
      if (lastFace >= 0) {
        if ((face == 0 && lastFace == 1) || (face == 1 && lastFace == 0)) continue;
        if ((face == 2 && lastFace == 3) || (face == 3 && lastFace == 2)) continue;
        if ((face == 4 && lastFace == 5) || (face == 5 && lastFace == 4)) continue;
      }
      
      KociembaCube newCube = cube.clone();
      newCube.applyMove(move);
      
      // Quick check: don't explore if it makes orientation worse
      int newOriented = _countOriented(newCube);
      if (newOriented < oriented - 2) continue; // Allow some worsening but not too much
      
      String moveStr = KociembaConstants.MOVE_NAMES[move];
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _idaSearchPhase1(newCube, depth - 1, newPath, face);
      
      if (result != null) {
        return result;
      }
    }
    
    return null;
  }
  
  List<int> _getPhase1MovesAll(KociembaCube cube, int lastFace) {
    // Try ALL moves, but prioritize those that improve orientation
    List<MapEntry<int, int>> moveScores = [];
    int currentOriented = _countOriented(cube);
    
    for (int move = 0; move < KociembaConstants.N_MOVE; move++) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      // Try the move and see how it affects orientation
      KociembaCube testCube = cube.clone();
      testCube.applyMove(move);
      int newOriented = _countOriented(testCube);
      
      // Score: how many more pieces become oriented
      int improvement = newOriented - currentOriented;
      
      // R, L, F, B moves are more likely to orient pieces
      if (face == 2 || face == 3 || face == 4 || face == 5) {
        improvement += 1; // Bonus for R/L/F/B moves
      }
      
      moveScores.add(MapEntry(move, improvement));
    }
    
    // Sort by improvement (best first)
    moveScores.sort((a, b) => b.value.compareTo(a.value));
    
    return moveScores.map((e) => e.key).toList();
  }
  
  int _countOriented(KociembaCube cube) {
    int oriented = 0;
    for (int i = 0; i < 8; i++) {
      if (cube.cornerOrient[i] == 0) oriented++;
    }
    for (int i = 0; i < 12; i++) {
      if (cube.edgeOrient[i] == 0) oriented++;
    }
    return oriented;
  }
  
  // PHASE 2: Permute all pieces
  List<String>? _phase2Search(KociembaCube cube) {
    // Check if already solved
    if (cube.isSolved()) {
      return [];
    }
    
    // Try increasing depths
    for (int depth = 1; depth <= PHASE2_MAX_DEPTH; depth++) {
      print("  Phase 2: searching depth $depth...");
      
      final stopwatch = Stopwatch()..start();
      List<String>? result = _idaSearchPhase2(cube, depth, [], -1);
      stopwatch.stop();
      
      if (result != null) {
        return result;
      }
      
      if (stopwatch.elapsedMilliseconds > TIMEOUT_MS) {
        print("  Phase 2 timeout at depth $depth");
        return null;
      }
    }
    
    return null;
  }
  
  List<String>? _idaSearchPhase2(KociembaCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (cube.isSolved()) {
        return path;
      }
      return null;
    }
    
    // Heuristic for phase 2: count misplaced pieces
    int misplaced = _countMisplaced(cube);
    int heuristic = (misplaced + 3) ~/ 4;
    
    if (heuristic > depth) return null;
    
    // Phase 2 moves: only U, D, R2, L2, F2, B2
    List<int> phase2Moves = KociembaConstants.PHASE2_MOVES;
    
    // Try moves in priority order
    List<int> orderedMoves = _getPhase2Moves(cube, phase2Moves, lastFace);
    
    for (int move in orderedMoves) {
      int face = move ~/ 3;
      
      // Skip redundant moves
      if (face == lastFace) continue;
      
      // Skip opposite face moves
      if (lastFace >= 0) {
        if ((face == 0 && lastFace == 1) || (face == 1 && lastFace == 0)) continue;
        if ((face == 2 && lastFace == 3) || (face == 3 && lastFace == 2)) continue;
        if ((face == 4 && lastFace == 5) || (face == 5 && lastFace == 4)) continue;
      }
      
      KociembaCube newCube = cube.clone();
      newCube.applyMove(move);
      
      String moveStr = KociembaConstants.MOVE_NAMES[move];
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _idaSearchPhase2(newCube, depth - 1, newPath, face);
      
      if (result != null) {
        return result;
      }
    }
    
    return null;
  }
  
  List<int> _getPhase2Moves(KociembaCube cube, List<int> moves, int lastFace) {
    // Prioritize moves that improve the state
    List<MapEntry<int, int>> moveScores = [];
    int currentMisplaced = _countMisplaced(cube);
    
    for (int move in moves) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      KociembaCube testCube = cube.clone();
      testCube.applyMove(move);
      int newMisplaced = _countMisplaced(testCube);
      
      // Improvement: lower is better
      int improvement = currentMisplaced - newMisplaced;
      moveScores.add(MapEntry(move, improvement));
    }
    
    // Sort by improvement (best first)
    moveScores.sort((a, b) => b.value.compareTo(a.value));
    
    return moveScores.map((e) => e.key).toList();
  }
  
  int _countMisplaced(KociembaCube cube) {
    int misplaced = 0;
    for (int i = 0; i < 8; i++) {
      if (cube.cornerPerm[i] != i) misplaced++;
    }
    for (int i = 0; i < 12; i++) {
      if (cube.edgePerm[i] != i) misplaced++;
    }
    return misplaced;
  }
  
  int _moveStringToIndex(String move) {
    for (int i = 0; i < KociembaConstants.MOVE_NAMES.length; i++) {
      if (KociembaConstants.MOVE_NAMES[i] == move) return i;
    }
    return 0;
  }
}

/// The main solver function - Synchronous
String solveKociemba(List<List<List<Color>>> faces) {
  try {
    final cube = RubiksCube(faces);
    final solver = KociembaSolver();
    return solver.solve(cube);
  } catch (e) {
    print('solveKociemba error: $e');
    return '';
  }
}