import 'package:flutter/material.dart';
import 'package:flutter_obj3d_test/obj3d/object3d_viewer.dart';

import 'package:vector_math/vector_math.dart' as Math;

import 'package:flutter_obj3d_test/utils/screen_utils.dart';

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 3d obj Parser/Viewer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Object3DDetails {
  String objPath;
  String objTexturePath;
  Math.Vector3 rotation;
  double zoom;
  Color color;

  Object3DDetails(this.objPath, this.objTexturePath, this.rotation, this.zoom, this.color);
}

List<Object3DDetails> _objects = [
  Object3DDetails("assets/box.obj", "assets/box.jpg", Math.Vector3(80, 10, 0), 80.0, Colors.white),
  Object3DDetails("assets/dog.obj", "assets/dog.jpg", Math.Vector3(34, 10, 0), 40.0, Colors.red),
  Object3DDetails("assets/wolf.obj", "assets/wolf.jpg", Math.Vector3(80, 10, 0), 80.0, Colors.blue),
  Object3DDetails("assets/fish.obj", "assets/fish.png", Math.Vector3(138, 10, 186), 41.0, Colors.green),
  Object3DDetails("assets/cat2.obj", "assets/cat2.jpg", Math.Vector3(12, 12, 0), 34.0, Colors.amber),
  Object3DDetails("assets/cat.obj", "assets/cat.jpg", Math.Vector3(80, 10, 0), 10.0, Colors.cyan),
];

class _MyHomePageState extends State<MyHomePage> {
  Object3DViewerController _object3DViewerController;
  int _drawModeIndex = 0;
  bool _showWireframe = false;
  int _objIndex = 4;

  List<DrawMode> _drawModes = [
    DrawMode.SHADED,
    DrawMode.TEXTURED,
    DrawMode.WIREFRAME,
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    _object3DViewerController = Object3DViewerController();
  }

  _nextObj() async {
    _objIndex++;
    if (_objIndex >= _objects.length) _objIndex = 0;
    setState(() {});

    Future.delayed(Duration(milliseconds: 50), () {
      _object3DViewerController.reload().then((_) {
        Future.delayed(Duration(milliseconds: 100), () {
          setState(() => {});
        });
      });
    });
  }

  _nextDrawMode() {
    _drawModeIndex++;
    if (_drawModeIndex >= _drawModes.length) _drawModeIndex = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtils.init(context);

    return Scaffold(
        backgroundColor: const Color(0xff353535), //TODO
        body: SafeArea(
            child: Stack(
          children: [
            Object3DViewer(
              centerPivot: false,
              gridsMaxTile: 20,
              gridsTileSize: 0.5,
              refreshMilliseconds: 10,
              size: Size(ScreenUtils.width, ScreenUtils.height),
              animationController: _object3DViewerController,
              onHorizontalDragUpdate: (d) {
                if (_objIndex == 4)
                  _object3DViewerController.rotateY(d); //cat2
                else
                  _object3DViewerController.rotateZ(-d);
              },
              onVerticalDragUpdate: (d) {
                _object3DViewerController.rotateX(d);
              },
              initialZoom: _objects[_objIndex].zoom,
              initialAngles: _objects[_objIndex].rotation,
              objPath: _objects[_objIndex].objPath,
              texturePath: _objects[_objIndex].objTexturePath,
              drawMode: _drawModes[_drawModeIndex],
              onZoomChangeListener: (zoom) => _objects[_objIndex].zoom = zoom,
              onRotationChangeListener: (Math.Vector3 rotation) => _objects[_objIndex].rotation.setFrom(rotation),
              color: _objects[_objIndex].color,
              showInfo: true,
              showWireframe: _showWireframe,
              wireframeColor: Colors.red,
              panDistanceToActivate: 40,
            ),
            Padding(
              child: Column(
                children: <Widget>[
                  FlatButton(
                    color: Colors.white,
                    child: Text("Draw mode"),
                    onPressed: () => _nextDrawMode(),
                  ),
                  FlatButton(
                    color: Colors.white,
                    child: Text("Next obj"),
                    onPressed: () => _nextObj(),
                  ),
                  SizedBox(
                    child: CheckboxListTile(
                      title: Text("Wireframe"),
                      value: _showWireframe,
                      onChanged: (v) => setState(() => _showWireframe = v),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    width: 200,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              padding: EdgeInsets.only(left: 10),
            )
          ],
        )));
  }
}
