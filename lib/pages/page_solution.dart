import 'package:flutter/material.dart';

class PageSolution extends StatelessWidget{

  final List<List<List<Color?>>> cubeFaces;

  const PageSolution({
    super.key,
    required this.cubeFaces,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Center(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            for (int faceIdx = 0; faceIdx < cubeFaces.length; faceIdx++) ...[
              Text(
                'Face $faceIdx',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              
              for (int rowIdx = 0; rowIdx < cubeFaces[faceIdx].length; rowIdx++) ...[
                Text('  Row $rowIdx:'),
                
                for (int cellIdx = 0; cellIdx < cubeFaces[faceIdx][rowIdx].length; cellIdx++) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text(
                      'Cell $cellIdx: Color description -> ${cubeFaces[faceIdx][rowIdx][cellIdx].toString()}',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                ],
              ],
              const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}