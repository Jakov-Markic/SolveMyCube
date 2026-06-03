/*Comment what to do in future 
1. Make title
2. Make bottom navigation (main, timer, setting)
- main will include grid view of all cubes that will be widgets that link to their respective page
- timer will just be a timer used for solving
- setting will be list of options: theme change, language option, constumer service, terms of service, etc.
3. Make custom widget and make grid view of it
4. (Optional) Make background of widget 3d

*/

import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

//maybe convert to separate json file and just import it
var cubeInfo = [
  {"title": "3x3", "link": "./link"},
  {"title": "2x2", "link": "./link2"}
];
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(117, 0, 210, 210),
          title: Align(
            alignment: Alignment.center,
            child: Text("Solve My Cube"),
          ),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          children: List.generate(cubeInfo.length, (generator){
            return CubeWidget(cubeInfo[generator]["title"]!);
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting")
          ],
        ),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(0.8, 1),
            colors: <Color>[
            Color.fromARGB(58, 90, 175, 194),
            Color.fromARGB(180, 0, 208, 255),
            ],
        ),),
        child: Align(
         alignment: Alignment.bottomCenter,
          child: Text.rich(
              TextSpan(
                text: widget.title,
                style: TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}