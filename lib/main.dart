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
import 'pages/pageMain.dart';
import 'pages/page3x3.dart';

void main() {
  runApp(const MaterialApp(
    home: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
  
}

class MainScreen extends StatefulWidget{
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() =>
    // TODO: implement createState
    _MainScreen();
  
}

class _MainScreen extends State<MainScreen>{
  int _currentIndex = 0;

  // 2. Put your imported page widgets into the list
  final List<Widget> _pages = [
    const MainPage(),
    const Page3x3(),
    const Page3x3(),
  ];

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
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer), 
              label: "Timer",
              ),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting")
          ],
        ),
      ),
    );
  }
}
