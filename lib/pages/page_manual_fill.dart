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

  List<int> numberOfCellsRemaining = List.filled(6, 9);
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual input"),
        backgroundColor: Color.fromARGB(117, 0, 210, 210),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 16,
        children: [
          Container(
            color: Colors.red,
            width: 32,
            height: 32,
          ),
          const Divider(
            color: Colors.black87,
            thickness: 15,
          ),
          RubiksFace(
            selectedColor: _selectedColor, 
            isRubikComplete: (value){
              setState(() {
                _isComplete = value;
              });
            },
          ),
          ColorPickerRow(
            numberOfCellsRemaining: [...numberOfCellsRemaining],
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (builder)=>PageSolution())
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Solve"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
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
  final List<int> numberOfCellsRemaining;

  const ColorPickerRow({
    super.key, 
    required this.onColorSelected,
    required this.numberOfCellsRemaining,
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
      child: ListView.separated(
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
              numberOfCellsRemaining: widget.numberOfCellsRemaining[index - 1],
              )
            );
        },
      ),

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
  
  final Function(bool value) isRubikComplete;

  const RubiksFace({
    super.key, 
    required this.selectedColor,
    required this.isRubikComplete
  });

  @override
  State<StatefulWidget> createState() => _RubiksFaceState();
}

class _RubiksFaceState extends State<RubiksFace>{

  static const _faceLabels = ['F', 'R', 'U', 'B', 'L', 'D'];

  final List<List<List<Color?>>> _allFaces = 
    List.generate(6, (_) => 
      List.generate(3, (_) =>
        List.generate(3, (_) => null,
      )
    )
  );

  int _currentFace = 0;

  void _paintCell(int row, int col) {
    setState(() {
      _allFaces[_currentFace][row][col] = widget.selectedColor;
    });
    widget.isRubikComplete(_isComplete);
  }

  void _switchFace(int faceIndex) {
    setState(() => _currentFace = faceIndex);
  }

  bool get _isComplete => _allFaces.every(
    (face) => face.every(
      (row) => row.every(
        (cell) => cell != null, 
      )
    ),
  );

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildGrid(),
          const SizedBox(width: 12),
          _buildFaceSelector(),
        ],
      );
    }

  Widget _buildGrid() {
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
                    color: _allFaces[_currentFace][row][col],
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.black),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFaceSelector() {
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
              onPressed: () => _switchFace(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.teal : Colors.grey[300],
                foregroundColor: isActive ? Colors.white : Colors.black87,
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