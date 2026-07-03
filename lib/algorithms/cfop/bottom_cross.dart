import 'package:flutter/material.dart';
import 'cfop.dart';



// --- 1. BOTTOM CROSS SOLVER ---

String solveBottomCross(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  // Solve all 4 cross edges sequentially by rotating the cube horizontally each time
  for (int i = 0; i < 4; i++) {
    Color cD = cube.getCenterColor(Face.D);
    Color cF = cube.getCenterColor(Face.F);

    // If already solved in the active slot, skip to the next one
    if (cube.grid[Face.D.index][0][1] == cD && cube.grid[Face.F.index][2][1] == cF) {
      cube.rotateCubeY();
      //steps.write("Y ");
      continue;
    }

    // Phase A: Find where the target (cD, cF) edge piece currently is and bring it to the top layer (U)
    String bringToTop = "";
    
    // Check Middle Layer slots
    if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cD, cF)) {bringToTop = "R U R'";}
    else if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cD, cF)) {bringToTop = "R' U R";}
    else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cD, cF)) {bringToTop = "L U L'";}
    else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cD, cF)) {bringToTop = "L' U L";}
    // Check Bottom Layer slots
    else if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF)) {bringToTop = "F F";} // Flipped at target position
    else if (matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF)) {bringToTop = "R R";}
    else if (matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF)) {bringToTop = "B B";}
    else if (matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) {bringToTop = "L L";}

    if (bringToTop.isNotEmpty) {
      cube.executeSequence(bringToTop);
      steps.write("$bringToTop ");
    }

    // Phase B: Now the piece is guaranteed to be on the top layer (U). 
    // Rotate the U layer until it rests directly at the Front-Up (UF) position.
    String alignTop = "";
    if (matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF)) {alignTop = "U'";}
    else if (matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF)) {alignTop = "U U";}
    else if (matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF)) {alignTop = "U";}

    if (alignTop.isNotEmpty) {
      cube.executeSequence(alignTop);
      steps.write("$alignTop ");
    }

    // Phase C: Insert the piece from UF into the bottom DF cross slot based on orientation
    String insert = "";
    if (cube.grid[Face.U.index][2][1] == cD) {
      // D color is facing upwards on top
      insert = "F F";
    } else {
      // D color is facing forward on Front face
      insert = "U' R' F R";
    }

    cube.executeSequence(insert);
    steps.write("$insert ");

    // Rotate the entire cube to work on the next cross slot
    cube.rotateCubeY();
    //steps.write("Y ");
  }

  return steps.toString().trim();
}

// -