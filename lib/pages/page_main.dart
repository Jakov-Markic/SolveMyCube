import 'package:flutter/material.dart';
import './library.dart' as page;

//maybe convert to separate json file and just import it
const List<Map<String, String>> cubeInfo = [
  {"title": "3x3", "link": "./pages/page3x3.dart"},
  {"title": "2x2", "link": "./pages/page3x3.dart"},
  {"title": "4x4", "link": "./pages/page3x3.dart"},
  {"title": "5x5", "link": "./pages/page3x3.dart"},
];

/// Cube sizes the solver actually supports right now. Anything else still
/// shows up in the grid (so people know it's coming) but is dimmed and
/// bounces the user with a toast instead of opening [page.PageCube].
const Set<String> kAvailableCubeSizes = {'3x3'};


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
  bool get _isAvailable => kAvailableCubeSizes.contains(widget.title);

  void _handleTap(BuildContext context) {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title} is not currently available.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => page.PageCube(title: widget.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Opacity(
        opacity: _isAvailable ? 1.0 : 0.4,
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
            onPressed: () => _handleTap(context),
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
      ),
    );
  }
}
