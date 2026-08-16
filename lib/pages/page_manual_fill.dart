import 'package:flutter/material.dart';
import '../cube_face.dart';
import '../widgets/widgets.dart';
import './page_solution.dart';

/// Manual sticker-entry flow: paint each face's 9 stickers by hand, edit the
/// active 6-color palette, and jump to [PageSolution] once every face is
/// fully and validly painted.
class PageManualFill extends StatefulWidget {
  final List<List<List<Color?>>>? initialCubeFaces;

  const PageManualFill({super.key, this.initialCubeFaces});

  @override
  State<StatefulWidget> createState() => _PageManualFillState();
}

class _PageManualFillState extends State<PageManualFill> {
  late List<Color> _activeColors;
  late Color _selectedColor;
  bool _isComplete = false;
  Face _selectedFace = Face.F;

  late final List<List<List<Color?>>> _allFaces;
  late final ValueNotifier<List<int>> _cellsRemainingNotifier;

  /// Sets up the working copy of [PageManualFill.initialCubeFaces] and
  /// derives the initial per-color remaining counts and Solve-button state
  /// from it.
  @override
  void initState() {
    super.initState();
    _activeColors = List<Color>.from(kFaceColorList);
    _selectedColor = _activeColors[0];
    _allFaces = _createFaces(widget.initialCubeFaces);
    final counts = _initialRemainingCounts(_allFaces);
    _cellsRemainingNotifier = ValueNotifier(counts);
    // So a capture that's already valid (or already over/under on some
    // color) shows the correct Solve button state immediately, not just
    // after the user's first tap.
    _isComplete = counts.every((c) => c == 0);
  }

  @override
  void dispose() {
    _cellsRemainingNotifier.dispose();
    super.dispose();
  }

  /// Builds the face grid, color picker, and (once complete) the Solve button.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual input"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          Container(
            color: theme.colorScheme.primary,
            width: 32,
            height: 32,
          ),
          Divider(
            color: theme.colorScheme.outlineVariant,
            thickness: 2,
          ),
          RubiksFace(
            selectedColor: _selectedColor,
            activeColors: _activeColors,
            allFaces: _allFaces,
            cellsRemainingNotifier: _cellsRemainingNotifier,
            selectedFace: _selectedFace,
            onFaceChanged: (face) => setState(() {
              _selectedFace = face;
            }),
            isRubikComplete: (value){
              setState(() {
                _isComplete = value;
              });
            },
          ),
          ColorPickerRow(
            activeColors: _activeColors,
            selectedColor: _selectedColor,
            cellsRemainingNotifier: _cellsRemainingNotifier,
            onColorSelected: (color)=>setState(() {
              _selectedColor = color;
            }),
            onEditPressed: _openColorEditor,
          ),
          const Divider(
            color: Colors.black87,
            thickness: 15,
          ),
          if(_isComplete)...[
            ElevatedButton.icon(
              onPressed: () {
                final List<List<List<Color>>> tempCubeFaces = _allFaces.map(
                  (face) => face.map(
                    (row) => row.cast<Color>().toList()
                  ).toList()
                ).toList();

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (builder)=>PageSolution(cubeFaces: tempCubeFaces,))
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Solve"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Builds a fresh 6-face/3x3 grid of null (unpainted) cells, copying in
  /// [initialFaces] cell-by-cell when provided.
  List<List<List<Color?>>> _createFaces(List<List<List<Color?>>>? initialFaces) {
    final faces = List<List<List<Color?>>>.generate(
      6,
      (_) => List<List<Color?>>.generate(3, (_) => List<Color?>.filled(3, null)),
    );

    if (initialFaces == null) {
      return faces;
    }

    for (int faceIndex = 0; faceIndex < faces.length; faceIndex++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          faces[faceIndex][row][col] = initialFaces[faceIndex][row][col];
        }
      }
    }

    return faces;
  }

  /// Remaining allowance per color (index matches [_activeColors] order).
  /// A real cube has exactly 9 stickers of each color,
  /// so this can go *negative* - e.g. -3 means 3 too many were placed (most
  /// often from a misclassified auto-capture) - which is intentional: it's
  /// what lets [_PageManualFillState._isComplete] require an exact 9-per-color
  /// split rather than just "no cell left blank", and lets the color picker
  /// flag the over-used color so the user knows what to fix.
  List<int> _initialRemainingCounts(List<List<List<Color?>>> faces) {
    final counts = List<int>.filled(6, 9);
    for (int faceIndex = 0; faceIndex < faces.length; faceIndex++) {
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          final color = faces[faceIndex][row][col];
          if (color == null) continue;
          final index = _activeColors.indexOf(color);
          if (index >= 0) {
            counts[index] = counts[index] - 1;
          }
        }
      }
    }
    return counts;
  }

  /// Opens the palette editor and, if the user confirms a new 6-color
  /// selection, applies it. Since a painted cell's meaning is tied to which
  /// color represents which face, changing the palette invalidates any
  /// existing capture - so the grid is cleared rather than left holding
  /// colors that may no longer be selectable.
  Future<void> _openColorEditor() async {
    final newPalette = await showDialog<List<Color>>(
      context: context,
      builder: (context) => ColorPaletteDialog(initialSelection: _activeColors),
    );

    if (newPalette == null) return;

    setState(() {
      _activeColors = newPalette;
      _selectedColor = _activeColors[0];
      for (final face in _allFaces) {
        for (final row in face) {
          for (int col = 0; col < row.length; col++) {
            row[col] = null;
          }
        }
      }
      _cellsRemainingNotifier.value = List<int>.filled(6, 9);
      _isComplete = false;
    });
  }
}
