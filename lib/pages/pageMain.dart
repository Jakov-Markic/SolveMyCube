import 'package:flutter/material.dart';

//maybe convert to separate json file and just import it
var cubeInfo = [
  {"title": "3x3", "link": "./pages/page3x3.dart"},
  {"title": "2x2", "link": "./"}
];


class MainPage extends StatelessWidget{
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Scaffold(
        body: GridView.count(
          crossAxisCount: 2,
          children: List.generate(cubeInfo.length, (generator){
            return CubeWidget(cubeInfo[generator]["title"]!);
          }),
        ),
      )
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
