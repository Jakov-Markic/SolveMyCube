import 'package:flutter/material.dart';
import './page_manual_fill.dart';
import '../algorithms/cfop/cfop.dart';

class PageSolution extends StatelessWidget{

  final List<List<List<Color>>> cubeFaces;

  const PageSolution({
    super.key,
    required this.cubeFaces,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // Calculate it once per build cycle
    final RubiksCube currentCube = RubiksCube(cubeFaces);
    String solution = solveCfop(currentCube.grid);
  final ValueNotifier<List<int>> cellsRemainingNotifier = 
    ValueNotifier(List.filled(6, 9));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center( // Added Center to make Column alignment work properly
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RubiksFace(
            selectedColor: Colors.white, 
            allFaces: currentCube.grid,
            cellsRemainingNotifier: cellsRemainingNotifier,
            isRubikComplete: (value){
              false;
            },
          ),
            Text(solution.isEmpty ? "Already Solved!" : solution),
          ],
        ),
      ),
    );
  }
}
