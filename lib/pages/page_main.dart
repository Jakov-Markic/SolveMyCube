import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

//maybe convert to separate json file and just import it
const List<Map<String, String>> cubeInfo = [
  {"title": "3x3", "link": "./pages/page3x3.dart"},
  {"title": "2x2", "link": "./pages/page3x3.dart"},
  {"title": "4x4", "link": "./pages/page3x3.dart"},
  {"title": "5x5", "link": "./pages/page3x3.dart"},
];

/// Home screen: a grid of cube-size tiles, one per entry in [cubeInfo].
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  /// Builds the 2-column grid of [CubeWidget] tiles.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.count(
        crossAxisCount: 2,
        children: List.generate(cubeInfo.length, (generator) {
          return CubeWidget(cubeInfo[generator]["title"]!);
        }),
      ),
    );
  }
}
