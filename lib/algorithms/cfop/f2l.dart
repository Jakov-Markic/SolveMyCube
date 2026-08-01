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
    
    // Check DFR corner (our current target slot)
    if (matchCorner(cube, Face.D, 0, 2, Face.F, 2, 2, Face.R, 2, 0, cD, cF, cR)) {
      // Corner is in DFR - check if it's already solved
      if (!ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], cD) ||
          !ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], cF) ||
          !ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], cR)) {
        extract = "R U R' U'"; // Sexy move to extract
      }
    }
    // Check other bottom slots for our corner
    else if (matchCorner(cube, Face.D, 2, 2, Face.R, 2, 2, Face.B, 2, 0, cD, cF, cR)) {
      extract = "R' U R"; // Extract from DBR
    } else if (matchCorner(cube, Face.D, 2, 0, Face.B, 2, 2, Face.L, 2, 0, cD, cF, cR)) {
      extract = "B' U B"; // Extract from DBL
    } else if (matchCorner(cube, Face.D, 0, 0, Face.L, 2, 2, Face.F, 2, 0, cD, cF, cR)) {
      extract = "L' U L"; // Extract from DFL
    }

    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Align corner on U layer directly above target slot (UFR position)
    String align = "";
    if (matchCorner(cube, Face.U, 0, 2, Face.R, 0, 2, Face.B, 0, 0, cD, cF, cR)) {
      align = "U"; // Corner is at UBR, need U to bring to UFR
    } else if (matchCorner(cube, Face.U, 0, 0, Face.B, 0, 2, Face.L, 0, 0, cD, cF, cR)) {
      align = "U2"; // Corner is at UBL, need U2 to bring to UFR
    } else if (matchCorner(cube, Face.U, 2, 0, Face.L, 0, 2, Face.F, 0, 0, cD, cF, cR)) {
      align = "U'"; // Corner is at UFL, need U' to bring to UFR
    }
    // If corner is already at UFR, no alignment needed

    if (align.isNotEmpty) {
      cube.executeSequence(align);
      steps.write("$align ");
    }

    // Run "Sexy Move" loop until all 3 colors align
    int attempts = 0;
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

    // Check if edge is already solved in FR slot
    bool edgeSolved = ColorUtils.areColorsEqual(cube.grid[Face.F.index][1][2], cF) && 
                      ColorUtils.areColorsEqual(cube.grid[Face.R.index][1][0], cR);
    
    if (!edgeSolved) {
      // Check if target edge is stuck in a middle layer slot and extract it
      String extract = "";
      
      // Check FR slot
      if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cF, cR)) {
        // Edge is in FR but wrong orientation or wrong piece
        extract = "R U R' U' F' U' F"; // Extract FR edge to top layer
      }
      // Check BR slot - FIXED
      else if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cF, cR)) {
        // Edge is in BR, extract it
        extract = "R' U' R U R' U' R U B U' B'"; // Proper BR extraction
      }
      // Check BL slot - FIXED  
      else if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cF, cR)) {
        // Edge is in BL, extract it
        extract = "B' U' B U B' U' B U L U' L'"; // Proper BL extraction
      }
      // Check FL slot - FIXED
      else if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cF, cR)) {
        // Edge is in FL, extract it
        extract = "L' U' L U L' U' L U F U' F'"; // Proper FL extraction
      }

      if (extract.isNotEmpty) {
        cube.executeSequence(extract);
        steps.write("$extract ");
      }

      // Now the edge should be in the top layer, insert it into FR slot
      String insert = "";
      
      // Case 1: Edge is at UF with F color on F face (correct orientation)
      if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cF) && 
          ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cR)) {
        insert = "U R U' R' U' F' U F";
      }
      // Case 2: Edge is at UR with F color on R face (needs rotation)
      else if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cR)) {
        insert = "U2 R U' R' U' F' U F";
      }
      // Case 3: Edge is at UB with F color on B face
      else if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cR)) {
        insert = "U' R U' R' U' F' U F";
      }
      // Case 4: Edge is at UL with F color on L face
      else if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cF) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cR)) {
        insert = "R U' R' U' F' U F";
      }
      // Case 5: Edge is at UR with F color on U face (flipped orientation)
      else if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cF)) {
        insert = "U' F' U F U R U' R'";
      }
      // Case 6: Edge is at UB with F color on U face
      else if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cF)) {
        insert = "F' U F U R U' R'";
      }
      // Case 7: Edge is at UL with F color on U face
      else if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cF)) {
        insert = "U F' U F U R U' R'";
      }
      // Case 8: Edge is at UF with F color on U face
      else if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cR) && 
               ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cF)) {
        insert = "U2 F' U F U R U' R'";
      }

      if (insert.isNotEmpty) {
        cube.executeSequence(insert);
        steps.write("$insert ");
      }
    }
    cube.rotateCubeY();
    steps.write("y ");
    
  }

  return steps.toString().trim();
}