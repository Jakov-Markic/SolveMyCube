import 'package:flutter/material.dart';

/// Horizontal strip of selectable sticker colors plus a palette-edit button.

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
        builder: (context, cellsRemaining, _) {
          return ListView.separated(
            padding: EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            itemCount: activeColors.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: onEditPressed,
                    icon: Icon(Icons.edit),
                  ),
                );
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Single color picker tile with a remaining-count number
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

  /// Builds the swatch with its remaining-count badge.
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
