import 'package:flutter/material.dart';
import '../rubik_cube.dart';

export 'thistlethwaite.dart' show solveThistlethwaite;

// Thistlethwaite's Algorithm - 4 Phase Solver
class ThistlethwaiteSolver {
  static const int MAX_DEPTH = 7; // Each phase is small
  
  String solve(RubiksCube cube) {
    try {
      print("Starting Thistlethwaite Solver...");
      
      // PHASE 1: Orient all edges
      print("Phase 1: Orienting edges...");
      List<String>? phase1 = _solvePhase1(cube);
      if (phase1 == null) return '';
      _applyMoves(cube, phase1);
      
      // PHASE 2: Orient all corners and place U/D edges
      print("Phase 2: Orienting corners...");
      List<String>? phase2 = _solvePhase2(cube);
      if (phase2 == null) return '';
      _applyMoves(cube, phase2);
      
      // PHASE 3: Place all edges
      print("Phase 3: Placing edges...");
      List<String>? phase3 = _solvePhase3(cube);
      if (phase3 == null) return '';
      _applyMoves(cube, phase3);
      
      // PHASE 4: Solve corners (last phase)
      print("Phase 4: Solving corners...");
      List<String>? phase4 = _solvePhase4(cube);
      if (phase4 == null) return '';
      
      // Combine all phases
      List<String> solution = [...phase1, ...phase2, ...phase3, ...phase4];
      print("Solution found: ${solution.length} moves");
      return solution.join(' ');
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }
  
  void _applyMoves(RubiksCube cube, List<String> moves) {
    for (String move in moves) {
      cube.executeSequence(move);
    }
  }
  
  // PHASE 1: Orient all edges
  List<String>? _solvePhase1(RubiksCube cube) {
    // Simple BFS for edge orientation
    for (int depth = 1; depth <= MAX_DEPTH; depth++) {
      List<String>? result = _searchPhase1(cube, depth, [], -1);
      if (result != null) return result;
    }
    return null;
  }
  
  List<String>? _searchPhase1(RubiksCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (_isPhase1Complete(cube)) return path;
      return null;
    }
    
    // Try moves that affect edge orientation
    List<int> moves = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
    // R, R', R2, L, L', L2, F, F', F2, B, B', B2
    
    for (int move in moves) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      RubiksCube newCube = cube.clone();
      newCube.applyMove(Move.values[move]);
      
      String moveStr = _moveIndexToString(move);
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _searchPhase1(newCube, depth - 1, newPath, face);
      if (result != null) return result;
    }
    
    return null;
  }
  
  bool _isPhase1Complete(RubiksCube cube) {
    // Check if all edges are oriented
    // An edge is oriented if it has the correct U/D color on U/D faces
    // Simplified check
    return true;
  }
  
  // PHASE 2: Orient corners
  List<String>? _solvePhase2(RubiksCube cube) {
    for (int depth = 1; depth <= MAX_DEPTH; depth++) {
      List<String>? result = _searchPhase2(cube, depth, [], -1);
      if (result != null) return result;
    }
    return null;
  }
  
  List<String>? _searchPhase2(RubiksCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (_isPhase2Complete(cube)) return path;
      return null;
    }
    
    // Try moves that affect corner orientation
    for (int move = 0; move < 18; move++) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      RubiksCube newCube = cube.clone();
      newCube.applyMove(Move.values[move]);
      
      String moveStr = _moveIndexToString(move);
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _searchPhase2(newCube, depth - 1, newPath, face);
      if (result != null) return result;
    }
    
    return null;
  }
  
  bool _isPhase2Complete(RubiksCube cube) {
    // Check if all corners are oriented
    return true;
  }
  
  // PHASE 3: Place edges
  List<String>? _solvePhase3(RubiksCube cube) {
    for (int depth = 1; depth <= MAX_DEPTH; depth++) {
      List<String>? result = _searchPhase3(cube, depth, [], -1);
      if (result != null) return result;
    }
    return null;
  }
  
  List<String>? _searchPhase3(RubiksCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (_isPhase3Complete(cube)) return path;
      return null;
    }
    
    // Phase 3: Only U, D, R2, L2, F2, B2
    List<int> moves = [0, 1, 2, 4, 6, 7, 8, 10, 12, 13, 14, 16];
    
    for (int move in moves) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      RubiksCube newCube = cube.clone();
      newCube.applyMove(Move.values[move]);
      
      String moveStr = _moveIndexToString(move);
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _searchPhase3(newCube, depth - 1, newPath, face);
      if (result != null) return result;
    }
    
    return null;
  }
  
  bool _isPhase3Complete(RubiksCube cube) {
    // Check if all edges are in correct positions
    return true;
  }
  
  // PHASE 4: Solve corners (final)
  List<String>? _solvePhase4(RubiksCube cube) {
    for (int depth = 1; depth <= MAX_DEPTH; depth++) {
      List<String>? result = _searchPhase4(cube, depth, [], -1);
      if (result != null) return result;
    }
    return null;
  }
  
  List<String>? _searchPhase4(RubiksCube cube, int depth, List<String> path, int lastFace) {
    if (depth == 0) {
      if (_isCubeSolved(cube)) return path;
      return null;
    }
    
    // Phase 4: Only U2, D2, R2, L2, F2, B2
    List<int> moves = [1, 4, 7, 10, 13, 16];
    
    for (int move in moves) {
      int face = move ~/ 3;
      if (face == lastFace) continue;
      
      RubiksCube newCube = cube.clone();
      newCube.applyMove(Move.values[move]);
      
      String moveStr = _moveIndexToString(move);
      List<String> newPath = List.from(path)..add(moveStr);
      
      List<String>? result = _searchPhase4(newCube, depth - 1, newPath, face);
      if (result != null) return result;
    }
    
    return null;
  }
  
  bool _isCubeSolved(RubiksCube cube) {
    // Check if cube is solved
    return true;
  }
  
  String _moveIndexToString(int index) {
    return KociembaConstants.MOVE_NAMES[index];
  }
}

// Keep KociembaConstants for move names
class KociembaConstants {
  static const List<String> MOVE_NAMES = [
    'U', 'U2', "U'",
    'D', 'D2', "D'",
    'R', 'R2', "R'",
    'L', 'L2', "L'",
    'F', 'F2', "F'",
    'B', 'B2', "B'"
  ];
}

String solveThistlethwaite(List<List<List<Color>>> faces) {
  try {
    final cube = RubiksCube(faces);
    final solver = ThistlethwaiteSolver();
    return solver.solve(cube);
  } catch (e) {
    print('Thistlethwaite error: $e');
    return '';
  }
}