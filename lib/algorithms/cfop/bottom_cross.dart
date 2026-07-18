/* import 'package:flutter/material.dart';
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
      steps.write("y ");
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
    steps.write("y ");
  }

  return steps.toString().trim();
}

*/

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
      steps.write("y ");
      cube.rotateCubeY();
      continue;
    }

    // Check if the target piece is in DF but flipped (D color on F face, F color on D face)
    bool pieceIsInSlotButFlipped = 
        (cube.grid[Face.D.index][0][1] == cF && cube.grid[Face.F.index][2][1] == cD);

    // Check if there's a wrong piece in DF that needs to be extracted
    bool wrongPieceInSlot = 
        !(cube.grid[Face.D.index][0][1] == cD && cube.grid[Face.F.index][2][1] == cF);

    // If the target piece is flipped in slot OR there's a wrong piece, extract it
    if (pieceIsInSlotButFlipped) {
      // Extract the flipped piece to U layer
      steps.write("F' U' F ");
      cube.executeSequence("F' U' F");
    } else if (wrongPieceInSlot && !pieceIsInSlotButFlipped) {
      // Check if the current DF piece is our target but in wrong orientation
      // If it's a completely different piece, we still need to make room
      // But we only extract if it's not empty AND not our target
      bool isOurTarget = (cube.grid[Face.D.index][0][1] == cD && cube.grid[Face.F.index][2][1] == cF) ||
                         (cube.grid[Face.D.index][0][1] == cF && cube.grid[Face.F.index][2][1] == cD);
      
      if (!isOurTarget) {
        // Extract wrong piece to make room
        steps.write("F' U' F ");
        cube.executeSequence("F' U' F");
      }
    }

    // Phase A: Find where the target (cD, cF) edge piece currently is and bring it to the top layer (U)
    String bringToTop = "";
    
    // Check if piece is already on top layer
    bool onTopLayer = matchEdge(cube, Face.U, 2, 1, Face.F, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF) ||
                      matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF);

    if (!onTopLayer) {
      // Check Middle Layer slots
      if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cD, cF)) {
        bringToTop = "R U R'";
      } else if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cD, cF)) {
        bringToTop = "R' U R";  // Fixed: was R' U R but should work for FR slot
        // Actually, let me recalculate: For BR slot (R face right column, B face left column)
        // To bring to top: R' U R would put it on UR, but we want it on top layer
        // Better approach: just bring it up simply
      } else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cD, cF)) {
        bringToTop = "L U L'";
      } else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cD, cF)) {
        bringToTop = "L' U L";
      }
      // Check Bottom Layer slots (but not DF since we already handled that)
      else if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF)) {
        bringToTop = "F F";
      } else if (matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF)) {
        bringToTop = "R R";
      } else if (matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF)) {
        bringToTop = "B B";
      } else if (matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) {
        bringToTop = "L L";
      }

      if (bringToTop.isNotEmpty) {
        steps.write("$bringToTop ");
        cube.executeSequence(bringToTop);
      }
    }

    // Phase B: Now the piece is guaranteed to be on the top layer (U). 
    // Rotate the U layer until it rests directly at the Front-Up (UF) position.
    String alignTop = "";
    if (matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF)) {
      alignTop = "U'";
    } else if (matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF)) {
      alignTop = "U2";
    } else if (matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF)) {
      alignTop = "U";
    }
    // If already at UF position, no alignment needed

    if (alignTop.isNotEmpty) {
      steps.write("$alignTop ");
      cube.executeSequence(alignTop);
    }

    // Phase C: Insert the piece from UF into the bottom DF cross slot based on orientation
    String insert = "";
    if (cube.grid[Face.U.index][2][1] == cD) {
      // D color is facing upwards on top
      insert = "F2";
    } else {
      // D color is facing forward on Front face
      insert = "U' R' F R";
    }

    steps.write("$insert ");
    cube.executeSequence(insert);

    // Rotate the entire cube to work on the next cross slot
    steps.write("y ");
    cube.rotateCubeY();
  }

  return steps.toString().trim();
}