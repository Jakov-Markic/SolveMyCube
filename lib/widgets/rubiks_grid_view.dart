import 'package:flutter/material.dart';
import '../cube_face.dart';

/// A 3x3 grid of paintable stickers for the currently selected cube face.
///
/// Fully controlled from the outside: [allFaces] holds the color of every
/// sticker on every face, [selectedFace] picks which face is shown, and
/// [selectedColor] is the color a tap will paint with. Used by the manual
/// fill flow, the live camera capture preview, and the read-only solution
/// step viewer (wrapped in `IgnorePointer` there).
class RubiksGridView extends StatefulWidget {
  /// Sticker colors for all 6 faces, indexed `[face][row][col]`.
  final List<List<List<Color?>>> allFaces;

  /// Which face's 3x3 grid is currently rendered.
  final Face selectedFace;

  /// Color applied to a cell when it is tapped.
  final Color selectedColor;

  /// Palette used to look up a tapped color's remaining-count index.
  ///
  /// Nullable so callers that only render a read-only preview (e.g.
  /// PageSolution's step-through view, which wraps this in IgnorePointer and
  /// never paints) don't need to know about the manual-fill palette editor.
  final List<Color>? activeColors;

  /// Called with `true` once every color's remaining allowance hits exactly
  /// zero, and `false` again as soon as that stops being true.
  final Function(bool value) isRubikComplete;

  /// Remaining sticker allowance per color, shared with the color picker row
  /// so both update in lockstep as cells are painted.
  final ValueNotifier<List<int>> cellsRemainingNotifier;

  const RubiksGridView({
    super.key,
    required this.allFaces,
    required this.selectedFace,
    required this.selectedColor,
    this.activeColors,
    required this.cellsRemainingNotifier,
    required this.isRubikComplete,
  });

  @override
  State<StatefulWidget> createState() => StateRubikGridView();
}

class StateRubikGridView extends State<RubiksGridView> {
  /// Builds the 3x3 sticker grid for [RubiksGridView.selectedFace].
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        children: [
          for (int row = 0; row < 3; row++)
            for (int col = 0; col < 3; col++)
              GestureDetector(
                onTap: () => _paintCell(row, col),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.allFaces[widget.selectedFace.index][row][col] ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Palette used to resolve a color to its remaining-count index; falls
  /// back to the default 6 face colors when no custom palette was supplied.
  List<Color> get _palette => widget.activeColors ?? kFaceColorList;

  /// Requires every color's remaining allowance to hit exactly 0 - not just
  /// "no cell left blank". A real cube always has exactly 9 stickers of each
  /// color, so this also catches an over/under-counted auto-capture (e.g. a
  /// lighting-confused red/orange misread) that filled all 54 cells but with
  /// an invalid color split; Solve stays hidden until the user corrects it.
  bool get _isComplete =>
      widget.cellsRemainingNotifier.value.every((remaining) => remaining == 0);

  /// Paints or clears cell ([row], [col]) of the selected face with
  /// [RubiksGridView.selectedColor], updates the shared remaining-count
  /// notifier, and reports the new completion state via
  /// [RubiksGridView.isRubikComplete].
  void _paintCell(int row, int col) {
    final oldColor = widget.allFaces[widget.selectedFace.index][row][col];

    final colorToApply = (widget.selectedColor == oldColor) ? null : widget.selectedColor;

    if (colorToApply == null && oldColor == null) return;

    final newIndex = colorToApply != null ? _palette.indexOf(colorToApply) : -1;
    final remaining = widget.cellsRemainingNotifier.value;

    // Check if out of color
    if (newIndex != -1 && remaining[newIndex] <= 0) return;

    // Update UI
    setState(() {
      widget.allFaces[widget.selectedFace.index][row][col] = colorToApply;
    });

    final oldIndex = oldColor != null ? _palette.indexOf(oldColor) : -1;
    final updated = List<int>.from(widget.cellsRemainingNotifier.value);

    // Update color numbering
    if (newIndex != -1) updated[newIndex]--;
    if (oldIndex != -1) updated[oldIndex]++;

    widget.cellsRemainingNotifier.value = updated;

    widget.isRubikComplete(_isComplete);
  }
}
