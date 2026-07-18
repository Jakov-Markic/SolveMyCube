import 'package:flutter/material.dart';
import 'package:solve_my_cube/algorithms/cfop/bottom_cross.dart';
import 'cfop.dart';


//-- 2. FIRST TWO LAYERS (F2L) SOLVER ---

String solveF2L(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  if(!cube.checkBottomCross()){
    steps.write(solveBottomCross(cube));
  }

  // Step A: Solve the 4 bottom corners first
  for (int i = 0; i < 4; i++) {
    Color cD = cube.getCenterColor(Face.D);
    Color cF = cube.getCenterColor(Face.F);
    Color cR = cube.getCenterColor(Face.R);

    // Kick target corner to top layer if stuck in a bottom slot
    String extract = "";
    if (matchCorner(cube, Face.D, 2, 2, Face.R, 2, 2, Face.B, 2, 0, cD, cF, cR)) {extract = "R' U R";}
    else if (matchCorner(cube, Face.D, 2, 0, Face.B, 2, 2, Face.L, 2, 0, cD, cF, cR)) {extract = "L' U L";}
    else if (matchCorner(cube, Face.D, 0, 0, Face.L, 2, 2, Face.F, 2, 0, cD, cF, cR)) {extract = "L U L'";}
    else if (matchCorner(cube, Face.D, 0, 2, Face.F, 2, 2, Face.R, 2, 0, cD, cF, cR)) {
      // It's in our active slot, check if it's already solved
      if (cube.grid[Face.D.index][0][2] != cD || cube.grid[Face.F.index][2][2] != cF) {
        extract = "R U R' U'";
      }
    }

    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Align the corner on the U layer directly above our target slot (UFR position)
    String align = "";
    if (matchCorner(cube, Face.U, 0, 2, Face.R, 0, 2, Face.B, 0, 0, cD, cF, cR)) {align = "U";}
    else if (matchCorner(cube, Face.U, 0, 0, Face.B, 0, 2, Face.L, 0, 0, cD, cF, cR)) {align = "U2";}
    else if (matchCorner(cube, Face.U, 2, 0, Face.L, 0, 2, Face.F, 0, 0, cD, cF, cR)) {align = "U'";}

    if (align.isNotEmpty) {
      cube.executeSequence(align);
      steps.write("$align ");
    }

    // Run the standard "Sexy Move" loop until the corner drops perfectly into the slot
    // Run the standard "Sexy Move" loop until the corner drops perfectly into the slot
    int attempts = 0;
    while (cube.grid[Face.D.index][0][2] != cD || cube.grid[Face.F.index][2][2] != cF) {
      cube.executeSequence("R U R' U'");
      steps.write("R U R' U' ");
      attempts++;
      if (attempts >= 6) {
        // The sexy move has order 6 — if we're still not solved after 6 reps,
        // the piece sitting here isn't actually the target corner.
        // That means extract/align above failed to detect/position it correctly.
        throw StateError(
          'F2L corner insert failed: target cD=$cD cF=$cF not resolved after 6 attempts. '
          'DFR slot has D=${cube.grid[Face.D.index][0][2]}, F=${cube.grid[Face.F.index][2][2]}. '
          'Likely missing case in extract/align logic for iteration $i.'
        );
      }
    }

    cube.rotateCubeY();
    steps.write("y ");
  }

  // Step B: Solve the 4 middle layer edges
  for (int i = 0; i < 4; i++) {
    Color cF = cube.getCenterColor(Face.F);
    Color cR = cube.getCenterColor(Face.R);

    // Kick edge to top layer if stuck incorrectly in a middle slot
    String extract = "";
    if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cF, cR)) {extract = "R' U' R U B U' B'";}
    else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cF, cR)) {extract = "B' U B";}
    else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cF, cR)) {extract = "L' U L";}
    else if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cF, cR)) {
      if (cube.grid[Face.F.index][1][2] != cF) {
        extract = "R U R' U' F' U F"; // Flipped in its own slot
      }
    }

    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Insert the edge into the Front-Right (FR) slot from the top layer
    String insert = "";
    if (cube.grid[Face.F.index][0][1] == cF && cube.grid[Face.U.index][2][1] == cR) {
      insert = "U R U' R' U' F' U F"; // Aligned with Front, goes Right
    } else if (cube.grid[Face.R.index][0][1] == cF && cube.grid[Face.U.index][1][2] == cR) {
      insert = "U2 R U' R' U' F' U F";
    } else if (cube.grid[Face.B.index][0][1] == cF && cube.grid[Face.U.index][0][1] == cR) {
      insert = "U' R U' R' U' F' U F";
    } else if (cube.grid[Face.L.index][0][1] == cF && cube.grid[Face.U.index][1][0] == cR) {
      insert = "R U' R' U' F' U F";
    } else if (cube.grid[Face.R.index][0][1] == cR && cube.grid[Face.U.index][1][2] == cF) {
      insert = "U' F' U F U R U' R'"; // Aligned with Right, goes Left
    } else if (cube.grid[Face.B.index][0][1] == cR && cube.grid[Face.U.index][0][1] == cF) {
      insert = "F' U F U R U' R'";
    } else if (cube.grid[Face.L.index][0][1] == cR && cube.grid[Face.U.index][1][0] == cF) {
      insert = "U F' U F U R U' R'";
    } else if (cube.grid[Face.F.index][0][1] == cR && cube.grid[Face.U.index][2][1] == cF) {
      insert = "U2 F' U F U R U' R'";
    }

    if (insert.isNotEmpty) {
      cube.executeSequence(insert);
      steps.write("$insert ");
    }

    cube.rotateCubeY();
    steps.write("y ");
  }

  return steps.toString().trim();
}

