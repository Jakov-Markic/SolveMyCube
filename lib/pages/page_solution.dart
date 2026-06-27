import 'package:flutter/material.dart';
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
    final String solution = solveCfop(cubeFaces);

    return Scaffold(
      body: Center( // Added Center to make Column alignment work properly
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(solution.isEmpty ? "Already Solved!" : solution),
          ],
        ),
      ),
    );
  }
}
