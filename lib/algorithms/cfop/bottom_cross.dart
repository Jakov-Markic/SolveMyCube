import 'package:flutter/material.dart';
import '../../color_utils.dart';
import 'cfop.dart';

// --- 1. BOTTOM CROSS SOLVER ---

String solveBottomCross(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  // Solve all 4 cross edges sequentially by rotating the cube horizontally each time
  for (int i = 0; i < 4; i++) {
    Color cD = cube.getCenterColor(Face.D);
    Color cF = cube.getCenterColor(Face.F);

    // If already solved in the active slot, skip to the next one
    if (ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][1], cD) && 
        ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][1], cF)) {
      steps.write("y ");
      cube.rotateCubeY();
      continue;
    }

    // Phase A: Bring target (cD, cF) edge piece to top layer (U)
    String bringToTop = "";
    
    bool onTopLayer = matchEdge(cube, Face.U, 2, 1, Face.F, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF);

    if (!onTopLayer) {
      // Check Middle Layer slots
      if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cD, cF)) {
        bringToTop = "R U R'";
      } else if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 2, cD, cF)) {
        bringToTop = "R' U R";  
      } else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 2, cD, cF)) {
        bringToTop = "L U L'";
      } else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cD, cF)) {
        bringToTop = "L' U L";
      }
      // Check Bottom Layer slots
      else if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF)) {
        bringToTop = "F2";
      } else if (matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF)) {
        bringToTop = "R2";
      } else if (matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF)) {
        bringToTop = "B2";
      } else if (matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) {
        bringToTop = "L2";
      }

      if (bringToTop.isNotEmpty) {
        steps.write("$bringToTop ");
        cube.executeSequence(bringToTop);
      }
    }

    // Phase B: Align piece at Front-Up (UF) position on U layer
    String alignTop = "";
    if (matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF)) {
      alignTop = "U'";
    } else if (matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF)) {
      alignTop = "U2";
    } else if (matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF)) {
      alignTop = "U";
    }

    if (alignTop.isNotEmpty) {
      steps.write("$alignTop ");
      cube.executeSequence(alignTop);
    }

    // Phase C: Insert piece into bottom DF slot
    String insert = "";
    if (ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cD)) {
      insert = "F2";
    } else {
      insert = "U' R' F R";
    }

    steps.write("$insert ");
    cube.executeSequence(insert);

    steps.write("y ");
    cube.rotateCubeY();
  }

  return steps.toString().trim();
}