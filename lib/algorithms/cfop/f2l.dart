import 'package:flutter/material.dart';
import 'cfop.dart';
import '../../color_utils.dart'; // Ensure this path matches your project

//-- 2. FIRST TWO LAYERS (F2L) SOLVER ---

String solveF2L(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  // Step A: Solve the 4 bottom corners first
  for (int i = 0; i < 4; i++) {
    Color cD = cube.getCenterColor(Face.D);
    Color cF = cube.getCenterColor(Face.F);
    Color cR = cube.getCenterColor(Face.R);

    // Kick target corner to top layer if stuck in a bottom slot
    String extract = "";
    // FIX: Corrected D-R-B, D-B-L, and D-L-F corner coordinates
    if (matchCorner(cube, Face.D, 2, 2, Face.R, 2, 2, Face.B, 2, 0, cD, cF, cR)) {
      extract = "R' U R";
    } else if (matchCorner(cube, Face.D, 2, 0, Face.B, 2, 2, Face.L, 2, 0, cD, cF, cR)) {
      extract = "B' U B";
    } else if (matchCorner(cube, Face.D, 0, 0, Face.L, 2, 2, Face.F, 2, 0, cD, cF, cR)) {
      extract = "L' U L";
    } else if (matchCorner(cube, Face.D, 0, 2, Face.F, 2, 2, Face.R, 2, 0, cD, cF, cR)) {
      // Active slot (DFR): check if already solved
      // FIX: Use ColorUtils to prevent extracting a perfectly solved corner
      if (!ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], cD) ||
          !ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], cF) ||
          !ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], cR)) {
        extract = "R U R' U'";
      }
    }

    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Align corner on U layer directly above target slot (UFR position)
    String align = "";
    if (matchCorner(cube, Face.U, 0, 2, Face.R, 0, 2, Face.B, 0, 0, cD, cF, cR)) {
      align = "U";
    } else if (matchCorner(cube, Face.U, 0, 0, Face.B, 0, 2, Face.L, 0, 0, cD, cF, cR)) {
      align = "U2";
    } else if (matchCorner(cube, Face.U, 2, 0, Face.L, 0, 2, Face.F, 0, 0, cD, cF, cR)) {
      align = "U'";
    }

    if (align.isNotEmpty) {
      cube.executeSequence(align);
      steps.write("$align ");
    }

    // Run "Sexy Move" loop until all 3 colors align
    int attempts = 0;
    // FIX: Use ColorUtils so the loop actually registers when the corner is solved
    while (!ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], cD) ||
           !ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], cF) ||
           !ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], cR)) {
      cube.executeSequence("R U R' U'");
      steps.write("R U R' U' ");
      attempts++;
      if (attempts >= 6) {
        throw StateError('F2L corner insert failed for target cD=$cD cF=$cF cR=$cR');
      }
    }

    cube.rotateCubeY();
    steps.write("y ");
  }

  // Step B: Solve the 4 middle layer edges
  for (int i = 0; i < 4; i++) {
    Color cF = cube.getCenterColor(Face.F);
    Color cR = cube.getCenterColor(Face.R);

    // Kick edge to top layer safely
    String extract = "";
    if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cF, cR)) {
      extract = "R' U' R U B U' B'";
    } else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cF, cR)) {
      extract = "B' U' B U L U' L'";
    } else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cF, cR)) {
      extract = "L' U' L U F U' F'";
    } else if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cF, cR)) {
      // FIX: Use ColorUtils to prevent extracting a perfectly solved edge
      if (!ColorUtils.areColorsEqual(cube.grid[Face.F.index][1][2], cF) || 
          !ColorUtils.areColorsEqual(cube.grid[Face.R.index][1][0], cR)) {
        extract = "R U R' U' F' U F";
      }
    }

    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Insert edge into FR slot from top layer
    String insert = "";
    // FIX: Replaced all strict equality "==" chains with ColorUtils
    if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cF) && 
        ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cR)) {
      insert = "U R U' R' U' F' U F";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cR)) {
      insert = "U2 R U' R' U' F' U F";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cR)) {
      insert = "U' R U' R' U' F' U F";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cR)) {
      insert = "R U' R' U' F' U F";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cF)) {
      insert = "U' F' U F U R U' R'";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cF)) {
      insert = "F' U F U R U' R'";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cF)) {
      insert = "U F' U F U R U' R'";
    } else if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cF)) {
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