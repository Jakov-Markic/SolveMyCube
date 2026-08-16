import 'package:flutter/material.dart';
import '../cube_face.dart';
import './page_solution.dart';

/// Alternate shades for each of the 6 default sticker colors, offered
/// alongside [kFaceColorList] in the palette editor since different cube
/// brands commonly ship with slightly different reds/oranges/greens/etc.
const List<Color> kAlternateColorList = [
  Colors.pink,
  Colors.lightBlue,
  Color(0xFFE0E0E0),
  Colors.deepOrange,
  Colors.teal,
  Colors.amber,
];

class PageManualFill extends StatefulWidget{
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
}

/// Fully controlled by [selectedColor]/[onColorSelected] - which tile is
/// highlighted is derived from the current color rather than tracked as
/// separate internal state, so the row stays in sync when [activeColors] is
/// replaced by the palette editor (e.g. no stale "selected index 2" pointing
/// at a color that's no longer in the palette).
class ColorPickerRow extends StatelessWidget {
  final List<Color> activeColors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onEditPressed;
  final ValueNotifier<List<int>> cellsRemainingNotifier;

  const ColorPickerRow({
    super.key,
    required this.activeColors,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onEditPressed,
    required this.cellsRemainingNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ValueListenableBuilder(
        valueListenable: cellsRemainingNotifier,
        builder: (context, cellsRemaining, _){
         return ListView.separated(
          padding: EdgeInsets.all(16),
          scrollDirection: Axis.horizontal,
          itemCount: activeColors.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if(index == 0){
              return SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: onEditPressed,
                  icon: Icon(Icons.edit),
              ));
            }
            final color = activeColors[index - 1];
            return Align(
              alignment: Alignment.center,
              child: ColorPickerTile(
                colorValue: color,
                width: 48,
                height: 48,
                selected: color == selectedColor,
                onTap: () => onColorSelected(color),
                numberOfCellsRemaining: cellsRemaining[index - 1],
              )
            );
          },
         );
      })
    );
  }
}

class ColorPickerTile extends StatelessWidget {
  final Color colorValue;
  final double height, width;
  final bool selected;
  final VoidCallback onTap;  
  final int numberOfCellsRemaining;

  const ColorPickerTile({
    super.key,
    required this.colorValue,
    required this.height,
    required this.width,
    required this.selected,
    required this.onTap,
    required this.numberOfCellsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: selected ? colorValue.withValues(alpha: 0.5) : colorValue,
              border: Border.all(
                color: selected ? Colors.white : Colors.black,
                width: selected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 4,
                  bottom: 4,
                  // Negative = too many of this color placed (usually a
                  // misclassified auto-capture) - flagged so it's obvious
                  // which color to go fix, not just that Solve is hidden.
                  child: Text(
                    "$numberOfCellsRemaining",
                    style: numberOfCellsRemaining < 0
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

/// Shows the selected face's 3x3 grid alongside the F/R/U/B/L/D selector.
/// Fully controlled by [selectedFace]/[onFaceChanged] - the caller owns which
/// face is "current" (this used to be private internal state, which meant a
/// parent had no way to know or drive which face was being edited).
class RubiksFace extends StatelessWidget{
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

class RubiksGridView extends StatefulWidget{

  final List<List<List<Color?>>> allFaces;
  final Face selectedFace;
  final Color selectedColor;
  // Nullable so callers that only render a read-only preview (e.g.
  // PageSolution's step-through view, which wraps this in IgnorePointer and
  // never paints) don't need to know about the manual-fill palette editor.
  final List<Color>? activeColors;
  final Function(bool value) isRubikComplete;
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

class StateRubikGridView extends State<RubiksGridView>{

  List<Color> get _palette => widget.activeColors ?? kFaceColorList;

  void _paintCell(int row, int col) {
  final oldColor = widget.allFaces[widget.selectedFace.index][row][col];

  final colorToApply = (widget.selectedColor == oldColor) ? null : widget.selectedColor;

  if (colorToApply == null && oldColor == null) return;

  final newIndex = colorToApply != null ? _palette.indexOf(colorToApply) : -1;
  final remaining = widget.cellsRemainingNotifier.value;

  //Check if out of color
  if (newIndex != -1 && remaining[newIndex] <= 0) return;

  //Update UI
  setState(() {
    widget.allFaces[widget.selectedFace.index][row][col] = colorToApply;
  });

  final oldIndex = oldColor != null ? _palette.indexOf(oldColor) : -1;
  final updated = List<int>.from(widget.cellsRemainingNotifier.value);
  
  //Update color numbering
  if (newIndex != -1) updated[newIndex]--; 
  if (oldIndex != -1) updated[oldIndex]++; 
  
  widget.cellsRemainingNotifier.value = updated;

  widget.isRubikComplete(_isComplete);
}
  // Requires every color's remaining allowance to hit exactly 0 - not just
  // "no cell left blank". A real cube always has exactly 9 stickers of each
  // color, so this also catches an over/under-counted auto-capture (e.g. a
  // lighting-confused red/orange misread) that filled all 54 cells but with
  // an invalid color split; Solve stays hidden until the user corrects it.
  bool get _isComplete =>
      widget.cellsRemainingNotifier.value.every((remaining) => remaining == 0);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
                    color: widget.allFaces[widget.selectedFace.index][row][col] ?? Theme.of(context).colorScheme.surfaceContainerHighest,
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
}

/// Face picker, fully controlled by [selectedFace]/[onFaceChanged] - no
/// internal state, so any parent (manual fill, the live camera scan, a
/// future 3D view) can drive and observe which face is selected.
class RubikFaceSelector extends StatelessWidget{
  final Face selectedFace;
  final ValueChanged<Face> onFaceChanged;

  const RubikFaceSelector({
    super.key,
    required this.selectedFace,
    required this.onFaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: Face.values.map((face) {
        final isActive = face == selectedFace;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 40,
            height: 30,
            child: ElevatedButton(
              onPressed: () => onFaceChanged(face),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                padding: EdgeInsets.zero,
                elevation: isActive ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                face.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// Lets the user pick exactly 6 sticker colors from a 12-color pool (the 6
/// current colors plus 6 common alternates), shown as two rows of 6. Pops
/// the chosen colors (in pool order) on confirm, or null on cancel.
class ColorPaletteDialog extends StatefulWidget {
  final List<Color> initialSelection;

  const ColorPaletteDialog({super.key, required this.initialSelection});

  @override
  State<ColorPaletteDialog> createState() => _ColorPaletteDialogState();
}

class _ColorPaletteDialogState extends State<ColorPaletteDialog> {
  static const int _requiredCount = 6;
  static final List<Color> _pool = [...kFaceColorList, ...kAlternateColorList];

  late final Set<Color> _selected = {...widget.initialSelection};

  void _toggle(Color color) {
    setState(() {
      if (_selected.contains(color)) {
        _selected.remove(color);
      } else if (_selected.length < _requiredCount) {
        _selected.add(color);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _selected.length == _requiredCount;

    return AlertDialog(
      title: const Text("Choose 6 colors"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_selected.length} / $_requiredCount selected",
              style: TextStyle(
                color: isValid ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text("Current", style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            _PaletteRow(
              colors: _pool.sublist(0, 6),
              selected: _selected,
              onTap: _toggle,
            ),
            const SizedBox(height: 12),
            Text("Alternatives", style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            _PaletteRow(
              colors: _pool.sublist(6, 12),
              selected: _selected,
              onTap: _toggle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isValid
              ? () => Navigator.of(context).pop(
                    _pool.where(_selected.contains).toList(),
                  )
              : null,
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final List<Color> colors;
  final Set<Color> selected;
  final ValueChanged<Color> onTap;

  const _PaletteRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((color) {
        final isSelected = selected.contains(color);
        return GestureDetector(
          onTap: () => onTap(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black45,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  )
                : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}