import 'cfop.dart';


String solvePLL(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

  // --- STEP 1: Permute Corners (Look for Headlights) ---
  bool foundHeadlights = false;
  int headlightRotations = 0;

  for (int i = 0; i < 4; i++) {
    if (cube.grid[Face.F.index][0][0] == cube.grid[Face.F.index][0][2]) {
      foundHeadlights = true;
      break;
    }
    cube.executeSequence("U");
    steps.write("U ");
    headlightRotations++;
  }

  if (foundHeadlights) {
    // Move headlights to the Left face so T-Perm can process them
    cube.executeSequence("U"); 
    steps.write("U ");
    
    // Execute T-Perm algorithm to fix all corners relative to each other
    String tPerm = "R U R' U' R' F R2 U' R' U' R U R' F'";
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
  } else {
    // No headlights exist anywhere (E-Perm/V-Perm scenario)
    // Run an initial T-Perm to create a set of headlights, then process them
    String tPerm = "R U R' U' R' F R2 U' R' U' R U R' F'";
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
    
    // Find where the new headlights landed and put them on the Left Face
    while (cube.grid[Face.L.index][0][0] != cube.grid[Face.L.index][0][2]) {
      cube.executeSequence("U");
      steps.write("U ");
    }
    
    cube.executeSequence(tPerm);
    steps.write("$tPerm ");
  }

  // Align corners to their actual matching side centers
  while (cube.grid[Face.F.index][0][0] != cube.getCenterColor(Face.F)) {
    cube.executeSequence("U");
    steps.write("U ");
  }

  // --- STEP 2: Permute Edges (U-Perm Loop) ---
  // All corners are now solved. Only edges remain.
  int safetyTimeout = 0;
  while (!cube.checkPLL() && safetyTimeout < 6) {
    safetyTimeout++;

    // Find if there is a fully completed side face bar
    int solvedSideOffset = -1;
    List<Face> sides = [Face.B, Face.L, Face.F, Face.R]; // Order matching standard back-placement
    for (int i = 0; i < 4; i++) {
      Face face = sides[i];
      if (cube.grid[face.index][0][0] == cube.grid[face.index][0][1]) {
        solvedSideOffset = i;
        break;
      }
    }

    if (solvedSideOffset != -1) {
      // Rotate the entire cube so that the fully solved side face is facing Back (B)
      for (int i = 0; i < solvedSideOffset; i++) {
        cube.executeSequence("Y");
        steps.write("Y ");
      }
    }

    // Apply the standard clockwise U-Perm edge cycler
    String uPerm = "R2 U R U R' U' R' U' R' U R'";
    cube.executeSequence(uPerm);
    steps.write("$uPerm ");

    // Rotate the cube back if we turned it using Y
    if (solvedSideOffset != -1) {
      for (int i = 0; i < solvedSideOffset; i++) {
        cube.executeSequence("Y"); // Reversal logic via looping full rotation or explicit Y'
      }
    }
  }

  // Final alignment adjustment layer shift
  while (cube.grid[Face.F.index][0][0] != cube.getCenterColor(Face.F)) {
    cube.executeSequence("U");
    steps.write("U ");
  }

  return steps.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}