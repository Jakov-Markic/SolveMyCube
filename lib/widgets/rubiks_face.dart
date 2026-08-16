import 'package:flutter/material.dart';
import '../cube_face.dart';
import 'rubiks_grid_view.dart';
import 'rubik_face_selector.dart';

/// Shows the selected face's 3x3 grid alongside the F/R/U/B/L/D selector.
///
/// Fully controlled by [selectedFace]/[onFaceChanged] - the caller owns
/// which face is "current" (this used to be private internal state, which
/// meant a parent had no way to know or drive which face was being edited).
class RubiksFace extends StatelessWidget {
  final Color selectedColor;
  final List<Color>? activeColors;
  final List<List<List<Color?>>> allFaces;
  final ValueNotifier<List<int>> cellsRemainingNotifier;
  final Face selectedFace;
  final ValueChanged<Face> onFaceChanged;
  final Function(bool value) isRubikComplete;

  const RubiksFace({
    super.key,
    required this.selectedColor,
    this.activeColors,
    required this.isRubikComplete,
    required this.allFaces,
    required this.cellsRemainingNotifier,
    required this.selectedFace,
    required this.onFaceChanged,
  });

  /// Lays out [RubiksGridView] next to [RubikFaceSelector].
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RubiksGridView(
          allFaces: allFaces,
          selectedFace: selectedFace,
          selectedColor: selectedColor,
          activeColors: activeColors,
          cellsRemainingNotifier: cellsRemainingNotifier,
          isRubikComplete: isRubikComplete,
        ),
        const SizedBox(width: 12),
        RubikFaceSelector(
          selectedFace: selectedFace,
          onFaceChanged: onFaceChanged,
        ),
      ],
    );
  }
}
