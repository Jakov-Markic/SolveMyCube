import 'package:flutter/material.dart';
import 'package:path/path.dart';

const defaultColorValue = [
  Colors.red, //F
  Colors.blue, //R
  Colors.white, //U
  Colors.orange, //B
  Colors.green, //L
  Colors.yellow, //D
];

class PageManualFill extends StatelessWidget {
  
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
          Divider(
            color: Colors.black87,
            thickness: 15,
          ),
          RubiksFace(),
          //maybe create this color list to be separate widget
          ColorPickerRow(),
            
        ],
      ),
    );
  }
}

class ColorPickerRow extends StatefulWidget {
  const ColorPickerRow({super.key});

  @override
  State<ColorPickerRow> createState() => _ColorPickerRowState();
}

class _ColorPickerRowState extends State<ColorPickerRow> {
  int? selectedIndex; // null = nothing selected

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        itemCount: defaultColorValue.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
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
              }),
              )
            );
        },
      ),

    );
  }
}

class ColorPickerTile extends StatelessWidget {  // ✅ no longer needs StatefulWidget
  final Color colorValue;
  final double height, width;
  final bool selected;
  final VoidCallback onTap;  // ✅ callback to notify parent

  const ColorPickerTile({
    super.key,
    required this.colorValue,
    required this.height,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,  // ✅ just calls parent's setState
      child: Container(
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
      ),
    );
  }
}
class RubiksFace extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SizedBox(
      height: 200,
      width: 200,
      child: GridView.count( 
      crossAxisCount: 3,
      children: List.generate(9, (generator){
        return ElevatedButton(
          onPressed: () => {},
          style: ButtonStyle(
            fixedSize: WidgetStateProperty.all(const Size(64, 64)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.black)
              ),
            ),
            
          ),
          child: const Text(""),
        );
      }),
      /* [
        ElevatedButton(
          onPressed: ()=>{}, 
          child: const Text(""),
        ),
        ElevatedButton(
          onPressed: ()=>{}, 
          child: const Text(""),
        ),
        ElevatedButton(
          onPressed: ()=>{}, 
          child: const Text(""),
        ),
        ElevatedButton(
          onPressed: ()=>{}, 
          child: const Text(""),
        )
      ] */
    ));
  }
}