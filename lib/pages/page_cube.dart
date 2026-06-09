import 'package:flutter/material.dart';
import 'package:solve_my_cube/globals.dart';
import 'package:solve_my_cube/pages/page_manual_fill.dart';
import './page_camera.dart';

class PageCube extends StatelessWidget {

  final String title;

  const PageCube({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(
          title
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 24,
          children: [
            Container(
              width: 400,
              height: 400,
              color: Color.fromARGB(230, 252, 0, 0),
              /* margin: EdgeInsetsGeometry.directional(
                bottom: 24
              ), */
            ),
            ElevatedButton.icon(
              onPressed: ()=>{
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PageCamera(camera: globalCameras.first),
                  ),
                )
              }, 
              icon: Icon(Icons.camera_alt),
              label: Text("Camera")
            ),
            Divider(
              height: 15,
              thickness: 2,
              indent: 64,
              endIndent: 64,
            ),
            ElevatedButton.icon(
              onPressed: ()=>{
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PageManualFill())
                )
              }, 
              icon: Icon(Icons.input),
              label: Text("Manul input")
            )
          ],
        ),
      ),
    );
  }
}