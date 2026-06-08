/*Comment what to do in future 
1. Make title
2. Make bottom navigation (main, timer, setting)
- main will include grid view of all cubes that will be widgets that link to their respective page
- timer will just be a timer used for solving
- setting will be list of options: theme change, language option, constumer service, terms of service, etc.
3. Make custom widget and make grid view of it
4. (Optional) Make background of widget 3d

*/

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pages/library.dart' as page;
import 'globals.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();

  globalCameras = await availableCameras();

  runApp(MainApp());
}

class MainApp extends StatelessWidget {

  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  late List<Widget> _pages;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pages = [
      const page.MainPage(),
      const page.PageSettings(),
      const page.PageTimer(),
    ];
  }
  // 2. Put your imported page widgets into the list
  

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
        body: _pages[_currentIndex],
        
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
