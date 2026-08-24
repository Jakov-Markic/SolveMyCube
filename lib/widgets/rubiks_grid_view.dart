import 'package:flutter/material.dart';
import '../cube_face.dart';

/// A 3x3 grid of paintable stickers for the currently selected cube face.
class RubiksGridView extends StatefulWidget {
  /// rubik's cube face colors
  final List<List<List<Color?>>> allFaces;
  final Face selectedFace;
  final Color selectedColor;
  final List<Color>? activeColors;

  /// Return true if all faces are filled properly
  final Function(bool value) isRubikComplete;

  /// Notifier for remaining count of each color
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

  /// Get palette of colors
  List<Color> get _palette => widget.activeColors ?? kFaceColorList;

  /// Get if all colors are used up
  bool get _isComplete =>
      widget.cellsRemainingNotifier.value.every((remaining) => remaining == 0);

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
