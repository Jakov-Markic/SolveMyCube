import 'package:flutter/material.dart';
import './page_solution.dart';

const defaultColorValue = [
  Colors.red, //F
  Colors.blue, //R
  Colors.white, //U
  Colors.orange, //B
  Colors.green, //L
  Colors.yellow, //D
];

class PageManualFill extends StatefulWidget{
  const PageManualFill({super.key});

  @override
  State<StatefulWidget> createState() => _PageManualFillState();
}

class _PageManualFillState extends State<PageManualFill> {

  Color _selectedColor = defaultColorValue[0];
  bool _isComplete = false;

  final List<List<List<Color?>>> _allFaces = 
    List.generate(6, (_) => 
      List.generate(3, (_) =>
        List.generate(3, (_) => null,
      )
    )
  );

  List<int> numberOfCellsRemaining = List.filled(6, 9);

  final ValueNotifier<List<int>> _cellsRemainingNotifier = 
    ValueNotifier(List.filled(6, 9));
  
  @override
  void dispose() {
    _cellsRemainingNotifier.dispose();
    super.dispose();
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
            allFaces: _allFaces,
            cellsRemainingNotifier: _cellsRemainingNotifier,
            isRubikComplete: (value){
              setState(() {
                _isComplete = value;
              });
            },
          ),
          ColorPickerRow(
            cellsRemainingNotifier: _cellsRemainingNotifier,
            onColorSelected: (color)=>setState(() {
              _selectedColor = color;
            })
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

class ColorPickerRow extends StatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueNotifier<List<int>> cellsRemainingNotifier;

  const ColorPickerRow({
    super.key, 
    required this.onColorSelected,
    required this.cellsRemainingNotifier,
  });

  @override
  State<ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<ColorPickerRow> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ValueListenableBuilder(
        valueListenable: widget.cellsRemainingNotifier, 
        builder: (context, cellsRemaining, _){
         return ListView.separated(
          padding: EdgeInsets.all(16),
          scrollDirection: Axis.horizontal,
          itemCount: defaultColorValue.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if(index == 0){
              return SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: ()=>{}, 
                  icon: Icon(Icons.edit),
              ));
            }
            return Align(
              alignment: Alignment.center,
              child: ColorPickerTile(
                colorValue: defaultColorValue[index - 1],
                width: 48, 
                height: 48,
                selected: selectedIndex == index,
                onTap: () => setState(() {
                  selectedIndex = index;
                  widget.onColorSelected(defaultColorValue[index - 1]);
                }),
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
              color: selected ? colorValue.withOpacity(0.5) : colorValue,
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
                  child: Text("$numberOfCellsRemaining"),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}

class RubiksFace extends StatefulWidget{
  final Color selectedColor;
  final List<List<List<Color?>>> allFaces;
  final ValueNotifier<List<int>> cellsRemainingNotifier;
  
  final Function(bool value) isRubikComplete;

  const RubiksFace({
    super.key, 
    required this.selectedColor,
    required this.isRubikComplete,
    required this.allFaces,
    required this.cellsRemainingNotifier,
  });

  @override
  State<StatefulWidget> createState() => _RubiksFaceState();
}

class _RubiksFaceState extends State<RubiksFace>{

  int _currentFace = 0;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RubiksGridView(
            allFaces: widget.allFaces,
            selectedFace: _currentFace,
            selectedColor: widget.selectedColor,
            cellsRemainingNotifier: widget.cellsRemainingNotifier,
            isRubikComplete: widget.isRubikComplete,
          ),
          const SizedBox(width: 12),
          RubikFaceSelector(
            switchFace: (value) {
              setState(() {
                _currentFace = value;
              });
            },
          ),
        ],
      );
    }

}

class RubiksGridView extends StatefulWidget{

  final List<List<List<Color?>>> allFaces;
  final int selectedFace;
  final Color selectedColor;
  final Function(bool value) isRubikComplete;
  final ValueNotifier<List<int>> cellsRemainingNotifier;

  const RubiksGridView({
    super.key, 
    required this.allFaces,
    required this.selectedFace,
    required this.selectedColor,
    required this.cellsRemainingNotifier,
    required this.isRubikComplete,
  });

  @override
  State<StatefulWidget> createState() => StateRubikGridView();
}

class StateRubikGridView extends State<RubiksGridView>{

  void _paintCell(int row, int col) {
  final oldColor = widget.allFaces[widget.selectedFace][row][col];
  
  final colorToApply = (widget.selectedColor == oldColor) ? null : widget.selectedColor;

  if (colorToApply == null && oldColor == null) return;

  final newIndex = colorToApply != null ? defaultColorValue.indexOf(colorToApply) : -1;
  final remaining = widget.cellsRemainingNotifier.value;
  
  //Check if out of color
  if (newIndex != -1 && remaining[newIndex] <= 0) return; 

  //Update UI
  setState(() {
    widget.allFaces[widget.selectedFace][row][col] = colorToApply;
  });

  final oldIndex = oldColor != null ? defaultColorValue.indexOf(oldColor) : -1;
  final updated = List<int>.from(widget.cellsRemainingNotifier.value);
  
  //Update color numbering
  if (newIndex != -1) updated[newIndex]--; 
  if (oldIndex != -1) updated[oldIndex]++; 
  
  widget.cellsRemainingNotifier.value = updated;

  widget.isRubikComplete(_isComplete);
}
  bool get _isComplete => widget.allFaces.every(
    (face) => face.every(
      (row) => row.every(
        (cell) => (cell != Colors.grey && cell != null), 
      )
    ),
  );

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
                    color: widget.allFaces[widget.selectedFace][row][col] ?? Theme.of(context).colorScheme.surfaceContainerHighest,
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

class RubikFaceSelector extends StatefulWidget{

  final Function(int value) switchFace;
  const RubikFaceSelector({super.key, required this.switchFace});

  @override
  State<StatefulWidget> createState() => StateRubikFaceSelector();
}

class StateRubikFaceSelector extends State<RubikFaceSelector> {
  
  static const _faceLabels = ['F', 'R', 'U', 'B', 'L', 'D'];
  int _currentFace = 0;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (index) {
        final isActive = _currentFace == index;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 40,
            height: 30,
            child: ElevatedButton(
              onPressed: () => {
                widget.switchFace(index),
                _currentFace = index,
              },
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
                _faceLabels[index],
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}