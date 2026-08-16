import 'package:flutter/material.dart';
import '../../color_utils.dart';
import 'cfop.dart';

// --- 1. BOTTOM CROSS SOLVER ---
String solveBottomCross(RubiksCube cube) {
  StringBuffer steps = StringBuffer();

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
    String bringToTop = _extractCrossEdgeToTop(cube, cD, cF);
    if (bringToTop.isNotEmpty) {
      steps.write("$bringToTop ");
      cube.executeSequence(bringToTop);
    }

    // Phase B: Align piece at Front-Up (UF) position on U layer
    String alignTop = _alignCrossEdgeAboveSlot(cube, cD, cF);
    if (alignTop.isNotEmpty) {
      steps.write("$alignTop ");
      cube.executeSequence(alignTop);
    }

    // Phase C: Insert piece into bottom DF slot
    String insert = _insertCrossEdge(cube, cD);
    steps.write("$insert ");
    cube.executeSequence(insert);

    steps.write("y ");
    cube.rotateCubeY();
  }

  return steps.toString().trim();
}

/// Brings the target cross edge up to the top layer (U), from wherever it
/// currently is: already on top (nothing to do), parked in a middle-layer
/// slot, or buried in a wrong spot on the bottom (D) layer.
///
/// Returns "" when it's already sitting somewhere in the top layer - in that
/// case `_alignCrossEdgeAboveSlot` handles rotating it into position.
String _extractCrossEdgeToTop(RubiksCube cube, Color cD, Color cF) {
  bool onTopLayer = matchEdge(cube, Face.U, 2, 1, Face.F, 0, 1, cD, cF) ||
      matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF) ||
      matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF) ||
      matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF);
  if (onTopLayer) return "";

  // Check Middle Layer slots
  if (matchEdge(cube, Face.F, 1, 2, Face.R, 1, 0, cD, cF)) return "R U R'";
  if (matchEdge(cube, Face.R, 1, 2, Face.B, 1, 0, cD, cF)) return "R' U R";
  if (matchEdge(cube, Face.B, 1, 2, Face.L, 1, 0, cD, cF)) return "L U L'";
  if (matchEdge(cube, Face.L, 1, 2, Face.F, 1, 0, cD, cF)) return "L' U L";

  // Check Bottom Layer slots
  if (matchEdge(cube, Face.D, 0, 1, Face.F, 2, 1, cD, cF)) return "F2";
  if (matchEdge(cube, Face.D, 1, 2, Face.R, 2, 1, cD, cF)) return "R2";
  if (matchEdge(cube, Face.D, 2, 1, Face.B, 2, 1, cD, cF)) return "B2";
  if (matchEdge(cube, Face.D, 1, 0, Face.L, 2, 1, cD, cF)) return "L2";

  return "";
}

/// Rotates just the U layer so the target edge - already confirmed to be
/// somewhere in the top layer - sits directly above its DF target slot, at
/// UF. Returns "" if it's already there.
String _alignCrossEdgeAboveSlot(RubiksCube cube, Color cD, Color cF) {
  if (matchEdge(cube, Face.U, 1, 2, Face.R, 0, 1, cD, cF)) return "U"; // UR -> UF
  if (matchEdge(cube, Face.U, 0, 1, Face.B, 0, 1, cD, cF)) return "U2"; // UB -> UF
  if (matchEdge(cube, Face.U, 1, 0, Face.L, 0, 1, cD, cF)) return "U'"; // UL -> UF
  return ""; // Already at UF
}

/// Drops the edge sitting at UF (already aligned directly above its DF
/// target slot) into that slot, in whichever of its 2 possible orientations
/// it currently has.
String _insertCrossEdge(RubiksCube cube, Color cD) {
  if (ColorUtils.areColorsEqual(cube.grid[Face.U.index][2][1], cD)) {
    return "F2"; // Down-color already faces up: flip straight down
  }
  return "U' R' F R"; // Down-color faces front: needs re-orienting on the way in
}
