import 'package:flutter/material.dart';
import 'cfop.dart';


String solveOLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();
  Color targetU = cube.getCenterColor(Face.U);

  // --- STEP 1: Orient Edges (Get the Yellow Cross) ---
  int edgeCount = 0;
  if (cube.grid[Face.U.index][0][1] == targetU) edgeCount++; // Back edge
  if (cube.grid[Face.U.index][1][0] == targetU) edgeCount++; // Left edge
  if (cube.grid[Face.U.index][1][2] == targetU) edgeCount++; // Right edge
  if (cube.grid[Face.U.index][2][1] == targetU) edgeCount++; // Front edge

  if (edgeCount == 0) {
    // Dot Case: Run Line algorithm, then L-shape algorithm
    cube.executeSequence("F R U R' U' F'");
    steps.write("F R U R' U' F' ");
    // Re-evaluate to handle the resulting L-shape
    edgeCount = 2; 
  }

  if (edgeCount == 2) {
    // Could be a Line or an L-shape. Let's align it.
    bool isLine = (cube.grid[Face.U.index][1][0] == targetU && cube.grid[Face.U.index][1][2] == targetU) ||
                  (cube.grid[Face.U.index][0][1] == targetU && cube.grid[Face.U.index][2][1] == targetU);

    if (isLine) {
      // Make sure the line is horizontal (Left-Right)
      if (cube.grid[Face.U.index][0][1] == targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
      cube.executeSequence("F R U R' U' F'");
      steps.write("F R U R' U' F' ");
    } else {
      // It's an L-shape. Rotate U until the L points Back and Left (0,1 and 1,0 are targetU)
      while (cube.grid[Face.U.index][0][1] != targetU || cube.grid[Face.U.index][1][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
      cube.executeSequence("F U R U' R' F'");
      steps.write("F U R U' R' F' ");
    }
  }

  // --- STEP 2: Orient Corners (Sune Loop) ---
  // Keep looping Sune until all 9 stickers on the U face match targetU
  int safetyTimeout = 0;
  while (!cube.checkOLL() && safetyTimeout < 8) {
    safetyTimeout++;
    int orientedCorners = 0;
    if (cube.grid[Face.U.index][0][0] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][0][2] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][2][0] == targetU) orientedCorners++;
    if (cube.grid[Face.U.index][2][2] == targetU) orientedCorners++;

    if (orientedCorners == 1) {
      // Sune Case: Rotate U until the single oriented corner is at the Front-Left (2,0)
      while (cube.grid[Face.U.index][2][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    } else if (orientedCorners == 2) {
      // Car/Chameleon structures: Rotate U until a yellow sticker faces Left at Front-Left-Up
      while (cube.grid[Face.L.index][0][2] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    } else if (orientedCorners == 0) {
      // Bowtie/Cross structures: Rotate U until a yellow sticker faces Front at Front-Left-Up
      while (cube.grid[Face.F.index][0][0] != targetU) {
        cube.executeSequence("U");
        steps.write("U ");
      }
    }

    cube.executeSequence("R U R' U R U2 R'");
    steps.write("R U R' U R U2 R' ");
  }

  return steps.toString().trim();
}
