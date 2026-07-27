import 'package:flutter/material.dart';
import './library.dart' as page;

//maybe convert to separate json file and just import it
const List<Map<String, String>> cubeInfo = [
  {"title": "3x3", "link": "./pages/page3x3.dart"},
  {"title": "2x2", "link": "./pages/page3x3.dart"}
];


class MainPage extends StatelessWidget{

  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        body: GridView.count(
          crossAxisCount: 2,
          children: List.generate(cubeInfo.length, (generator){
            return CubeWidget(cubeInfo[generator]["title"]!);
          }),
        ),
      );
  }
}


class CubeWidget extends StatefulWidget {
  final String title; 

  const CubeWidget(this.title, {super.key});

  @override
  State<CubeWidget> createState() => _CubeWidgetState();
}

class _CubeWidgetState extends State<CubeWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: const Alignment(0.8, 1),
            colors: <Color>[
              Theme.of(context).colorScheme.primary.withOpacity(0.55),
              Theme.of(context).colorScheme.secondary.withOpacity(0.95),
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: ()=>{
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => page.PageCube(title: widget.title),
              ),
            )
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 32,
            ),
          ),
        ),
      ),
    );
  }
}
