import 'package:flutter/material.dart';
import '../cube_face.dart';

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

  /// Builds the "N / 6 selected" header plus the current and alternate rows.
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

  // ---------------------------------------------------------------------
  // Implementation
  // ---------------------------------------------------------------------

  /// Toggles [color] in the selection, ignoring taps that would exceed
  /// [_requiredCount].
  void _toggle(Color color) {
    setState(() {
      if (_selected.contains(color)) {
        _selected.remove(color);
      } else if (_selected.length < _requiredCount) {
        _selected.add(color);
      }
    });
  }
}

/// One row of tappable color swatches used by [ColorPaletteDialog].
class _PaletteRow extends StatelessWidget {
  final List<Color> colors;
  final Set<Color> selected;
  final ValueChanged<Color> onTap;

  const _PaletteRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  /// Builds one circular swatch per color, checkmarking selected ones.
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
