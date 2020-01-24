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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Object3DViewerController _object3DViewerController;
  int _drawModeIndex = 0;
  bool _showWireframe = false;
  int _objIndex = 0;
  //Color _rndColor = randomColor();

  List<DrawMode> _drawModes = [
    DrawMode.SHADED,
    DrawMode.TEXTURED,
    DrawMode.WIREFRAME,
  ];

  List<String> _objPaths = [
    "assets/box.obj",
    "assets/dog.obj",
    "assets/wolf.obj",
    "assets/fish.obj",
    "assets/cat2.obj",
    "assets/cat.obj",
  ];
  List<String> _objTexturePaths = [
    "assets/box.jpg",
    "assets/dog.jpg",
    "assets/wolf.jpg",
    "assets/fish.png",
    "assets/cat2.jpg",
    "assets/cat.jpg",
  ];
  List<Math.Vector3> _angles = [
    Math.Vector3(80, 10, 0),
    Math.Vector3(0, 10, 0),
    Math.Vector3(280, 10, 0),
    Math.Vector3(0, 10, 0),
    Math.Vector3(280, 10, 0),
    Math.Vector3(0, 10, 0),
  ];
  List<double> _zooms = [
    80.0,
    40.5,
    41.0,
    18.0,
    8.0,
    2.0,
  ];
  List<Color> _colors = [
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.cyan,
  ];

  /*
  List<String> _objPaths = [
    "assets/barrels.obj",
    "assets/chess.obj",
    "assets/cottage.obj",
    "assets/e.obj",
    "assets/lcd.obj",
  ];
  List<String> _objTexturePaths = [
    "assets/barrels.png",
    "assets/chess.jpg",
    "assets/cottage.png",
    "assets/e.png",
    "assets/lcd.jpg",
  ];
  List<Math.Vector3> _angles = [
    Math.Vector3(80, 10, 0),
    Math.Vector3(0, 10, 0),
    Math.Vector3(280, 10, 0),
    Math.Vector3(0, 10, 0),
    Math.Vector3(280, 10, 0),
    Math.Vector3(0, 10, 0),
  ];
  List<double> _zooms = [
    80.0,
    40.5,
    41.0,
    18.0,
    8.0,
    2.0,
  ];
   */

  _nextObj() async {
    //_rndColor = randomColor();
    _objIndex++;
    if (_objIndex >= _objPaths.length) _objIndex = 0;
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
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    _object3DViewerController = Object3DViewerController();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtils.init(context);

    return Scaffold(
        backgroundColor: Colors.blueGrey,
        body: SafeArea(
            child: Stack(
          children: [
            Object3DViewer(
              refreshMilliseconds: 10,
              size: Size(ScreenUtils.width, ScreenUtils.height),
              animationController: _object3DViewerController,
              onHorizontalDragUpdate: (d) {
                if (_objIndex == 4)
                  _object3DViewerController.rotateY(d); //macska1
                else
                  _object3DViewerController.rotateZ(-d);
              },
              onVerticalDragUpdate: (d) {
                _object3DViewerController.rotateX(d);
              },
              initialZoom: _zooms[_objIndex],
              initialAngles: _angles[_objIndex],
              objPath: _objPaths[_objIndex],
              texturePath: _objTexturePaths[_objIndex],
              drawMode: _drawModes[_drawModeIndex],
              onZoomChangeListener: (zoom) => _zooms[_objIndex] = zoom,
              onRotationChangeListener: (Math.Vector3 angles) => _angles[_objIndex] = angles,
              color: _colors[_objIndex],
              showInfo: true,
              showWireframe: _showWireframe,
              wireframeColor: Colors.red,
              panDistanceToActivate: 40,
            ),
            Column(
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
                CheckboxListTile(
                  title: Text("Wireframe"),
                  value: _showWireframe,
                  onChanged: (v) => setState(() => _showWireframe = v),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
            )
          ],
        )));
  }
}
