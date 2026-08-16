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
    String extract = _extractCornerFromBottomSlot(cube, cD, cF, cR);
    if (extract.isNotEmpty) {
      cube.executeSequence(extract);
      steps.write("$extract ");
    }

    // Align corner on U layer directly above target slot (UFR position)
    String align = _alignCornerAboveSlot(cube, cD, cF, cR);
    if (align.isNotEmpty) {
      cube.executeSequence(align);
      steps.write("$align ");
    }

    // Drop the aligned corner into its slot
    String insert = _insertCornerIntoSlot(cube, cD, cF, cR);
    if (insert.isNotEmpty) {
      cube.executeSequence(insert);
      steps.write("$insert ");
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
      String extract = _extractEdgeFromMiddleSlot(cube, cF, cR);
      if (extract.isNotEmpty) {
        cube.executeSequence(extract);
        steps.write("$extract ");
      }

      // Now the edge should be in the top layer, insert it into FR slot
      String insert = _insertEdgeFromTop(cube, cF, cR);
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

/// Pops the target corner out of a *wrong* bottom-layer slot (DFR/DBR/DBL/DFL)
/// and up into the top layer, using the slot-specific "sexy move" commutator
/// for that corner (each one is a self-inverse-ish R/U or B/U or L/U pattern,
/// so it never disturbs anything outside the R/B/L face it turns).
///
/// Returns "" when there's nothing to extract - either the corner is already
/// correctly placed in DFR, or it's not stuck in a bottom slot at all (it's
/// somewhere in the top layer already, which `_alignCornerAboveSlot` handles).
String _extractCornerFromBottomSlot(RubiksCube cube, Color cD, Color cF, Color cR) {
  if (matchCorner(cube, Face.D, 0, 2, Face.F, 2, 2, Face.R, 2, 0, cD, cF, cR)) {
    // Right colors, but is it actually twisted correctly, or just parked here?
    bool alreadySolved = ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], cD) &&
        ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], cF) &&
        ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], cR);
    return alreadySolved ? "" : "R U R' U'"; // Sexy move to extract
  }
  if (matchCorner(cube, Face.D, 2, 2, Face.R, 2, 2, Face.B, 2, 0, cD, cF, cR)) {
    return "R' U R"; // Extract from DBR
  }
  if (matchCorner(cube, Face.D, 2, 0, Face.B, 2, 2, Face.L, 2, 0, cD, cF, cR)) {
    return "B' U B"; // Extract from DBL
  }
  if (matchCorner(cube, Face.D, 0, 0, Face.L, 2, 2, Face.F, 2, 0, cD, cF, cR)) {
    return "L' U L"; // Extract from DFL
  }
  return "";
}

/// Rotates just the U layer so the target corner - already confirmed to be
/// somewhere in the top layer - sits directly above its DFR target slot, at
/// UFR. Returns "" if it's already there.
String _alignCornerAboveSlot(RubiksCube cube, Color cD, Color cF, Color cR) {
  if (matchCorner(cube, Face.U, 0, 2, Face.R, 0, 2, Face.B, 0, 0, cD, cF, cR)) {
    return "U"; // Corner is at UBR, need U to bring it to UFR
  }
  if (matchCorner(cube, Face.U, 0, 0, Face.B, 0, 2, Face.L, 0, 0, cD, cF, cR)) {
    return "U2"; // Corner is at UBL, need U2 to bring it to UFR
  }
  if (matchCorner(cube, Face.U, 2, 0, Face.L, 0, 2, Face.F, 0, 0, cD, cF, cR)) {
    return "U'"; // Corner is at UFL, need U' to bring it to UFR
  }
  return ""; // Already at UFR, no alignment needed
}

/// Inserts the corner sitting at UFR (already aligned directly above its
/// DFR target slot) into that slot.
///
/// A corner aligned above its slot only has 3 possible twists, and each one
/// has its own short, fixed R/U-only algorithm that solves it in a single
/// shot - which one to run is looked up directly from which face carries the
/// down-color (D-center) sticker. This replaces retrying the plain "sexy
/// move" (R U R' U') in a loop until the colors happened to line up, which
/// could take anywhere from 1 to 6 repeats and had no real guarantee of
/// terminating beyond an emergency abort after 6 tries.
///
/// All 3 algorithms only turn R and U, so - same as the extraction step -
/// they never disturb corners already solved on the B/L faces.
String _insertCornerIntoSlot(RubiksCube cube, Color cD, Color cF, Color cR) {
  if (ColorUtils.areColorsEqual(cube.grid[Face.D.index][0][2], cD) &&
      ColorUtils.areColorsEqual(cube.grid[Face.F.index][2][2], cF) &&
      ColorUtils.areColorsEqual(cube.grid[Face.R.index][2][0], cR)) {
    return ""; // Already solved (came in pre-aligned and correctly twisted)
  }

  if (ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][2], cD)) {
    return "R2 U R2 U' R2"; // Down-color faces up
  }
  if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][2], cD)) {
    return "U R U' R'"; // Down-color faces the front
  }
  // Only remaining possibility: down-color faces the right.
  return "R U R'";
}

/// Pops the target edge out of a *wrong* middle-layer slot (FR/BR/BL/FL) and
/// up into the top layer. Returns "" if it isn't stuck in a middle slot (it's
/// either already solved, or already sitting in the top layer waiting for
/// `_insertEdgeFromTop`).
String _extractEdgeFromMiddleSlot(RubiksCube cube, Color cF, Color cR) {
  if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cF, cR)) {
    // Edge is in FR but wrong orientation or wrong piece
    return "R U R' U' F' U' F"; // Extract FR edge to top layer
  }
  if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cF, cR)) {
    // Edge is in BR, extract it (FR pattern rotated one slot around: F->R, R->B)
    return "B U B' U' R' U' R";
  }
  if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cF, cR)) {
    // Edge is in BL, extract it (FR pattern rotated two slots around: F->B, R->L)
    return "L U L' U' B' U' B";
  }
  if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cF, cR)) {
    // Edge is in FL, extract it (FR pattern rotated three slots around: F->L, R->F)
    return "F U F' U' L' U' L";
  }
  return "";
}

/// Inserts the target edge - now somewhere in the top layer - into the FR
/// slot, picking the one of 8 standard cases (4 top positions x 2
/// orientations) that matches where it currently sits.
String _insertEdgeFromTop(RubiksCube cube, Color cF, Color cR) {
  // Case 1: Edge is at UF with F color on F face (correct orientation)
  if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cF) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cR)) {
    return "U R U' R' U' F' U F";
  }
  // Case 2: Edge is at UR with F color on R face (needs rotation)
  if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cF) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cR)) {
    return "U2 R U' R' U' F' U F";
  }
  // Case 3: Edge is at UB with F color on B face
  if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cF) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cR)) {
    return "U' R U' R' U' F' U F";
  }
  // Case 4: Edge is at UL with F color on L face
  if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cF) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cR)) {
    return "R U' R' U' F' U F";
  }
  // Case 5: Edge is at UR with F color on U face (flipped orientation)
  if (ColorUtils.areColorsEqual(cube.grid[Face.R.index][0][1], cR) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][2], cF)) {
    return "U' F' U F U R U' R'";
  }
  // Case 6: Edge is at UB with F color on U face
  if (ColorUtils.areColorsEqual(cube.grid[Face.B.index][0][1], cR) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][0][1], cF)) {
    return "F' U F U R U' R'";
  }
  // Case 7: Edge is at UL with F color on U face
  if (ColorUtils.areColorsEqual(cube.grid[Face.L.index][0][1], cR) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][1][0], cF)) {
    return "U F' U F U R U' R'";
  }
  // Case 8: Edge is at UF with F color on U face
  if (ColorUtils.areColorsEqual(cube.grid[Face.F.index][0][1], cR) &&
      ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cF)) {
    return "U2 F' U F U R U' R'";
  }
  return "";
}
