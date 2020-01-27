import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_obj3d_test/obj3d/object3d_viewer.dart';
import 'package:provider/provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChangeVariants()),
      ],
      child: Consumer<ChangeVariants>(
        builder: (context, cv, _) {
          return MaterialApp(
            title: 'Flutter 3d obj Parser/Viewer Demo',
            theme: ThemeData(primarySwatch: Colors.blue),
            home: MyHomePage(),
          );
        },
      ),
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
  Color color, lightColor;
  double gridTileSize;

  Object3DDetails(this.objPath, this.objTexturePath, this.rotation, this.zoom, {this.color = Colors.black, this.lightColor = Colors.white, this.gridTileSize = 0.5});
}

List<Object3DDetails> _objects = [
  Object3DDetails(
    "assets/box.obj",
    "assets/box.jpg",
    Math.Vector3(80, 10, 0),
    80,
    color: Colors.black.withOpacity(0.7),
    lightColor: Colors.white.withOpacity(0.3),
  ),
  Object3DDetails(
    "assets/hubble.obj",
    "assets/hubble.png",
    Math.Vector3(282, 10, 135),
    3.5,
    color: Colors.black.withOpacity(0.7),
    lightColor: Colors.white.withOpacity(0.3),
    gridTileSize: 10.0,
  ),
  Object3DDetails(
    "assets/dog.obj",
    "assets/dog.jpg",
    Math.Vector3(34, 10, 0),
    40,
    color: Colors.black.withOpacity(0.8),
    lightColor: Colors.white.withOpacity(0.2),
  ),
  Object3DDetails(
    "assets/fish.obj",
    "assets/fish.png",
    Math.Vector3(138, 10, 186),
    41,
    color: Colors.green.withOpacity(0.5),
    lightColor: Colors.yellow.withOpacity(0.5),
  ),
  Object3DDetails(
    "assets/cat2.obj",
    "assets/cat2.jpg",
    Math.Vector3(12, 12, 0),
    34,
    color: Colors.amber.withOpacity(0.5),
    lightColor: Colors.black.withOpacity(0.5),
  ),
  Object3DDetails(
    "assets/cat.obj",
    "assets/cat.jpg",
    Math.Vector3(80, 10, 0),
    10,
    color: Colors.red.withOpacity(0.6),
    lightColor: Colors.green.withOpacity(0.4),
    gridTileSize: 5.0,
  ),
];

class ChangeVariants with ChangeNotifier {
  int _drawModeIndex = 0;
  bool _showWireframe = false;
  bool _useNewAlgorithm = true;
  int _objIndex = 0;
  double _lightAngle = 0.0;
  Math.Vector3 _lightPosition = Math.Vector3(20.0, 20.0, 10.0);

  int get objIndex => _objIndex;

  double get lightAngle => _lightAngle;

  Math.Vector3 get lightPosition => _lightPosition;

  int get drawModeIndex => _drawModeIndex;

  bool get showWireframe => _showWireframe;

  bool get useNewAlgorithm => _useNewAlgorithm;

  set objIndex(int value) {
    _objIndex = value;
    notifyListeners();
  }

  set drawModeIndex(int value) {
    _drawModeIndex = value;
    notifyListeners();
  }

  set showWireframe(bool value) {
    _showWireframe = value;
    notifyListeners();
  }

  set useNewAlgorithm(bool value) {
    _useNewAlgorithm = value;
    notifyListeners();
  }

  set lightAngle(double value) {
    _lightAngle = value;
    notifyListeners();
  }

  set lightPosition(Math.Vector3 value) {
    _lightPosition = value;
    notifyListeners();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Object3DViewerController _object3DViewerController;
  Timer _renderTimer;
  ChangeVariants _changeVariantsSet;

  List<DrawMode> _drawModes = [
    DrawMode.TEXTURED,
    DrawMode.SHADED,
    DrawMode.WIREFRAME,
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    _changeVariantsSet = Provider.of<ChangeVariants>(context, listen: false);
    _object3DViewerController = Object3DViewerController();
    _startTimer();
  }

  _startTimer() {
    _renderTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final d = 25.0;
      _changeVariantsSet.lightAngle += 1.8;
      if (_changeVariantsSet.lightAngle > 360) _changeVariantsSet.lightAngle = 0;
      double fx = sin(Math.radians(_changeVariantsSet.lightAngle)) * d;
      double fz = cos(Math.radians(_changeVariantsSet.lightAngle)) * d;
      _changeVariantsSet.lightPosition.setValues(fx, fx, fz);
      _object3DViewerController.setLightPosition(_changeVariantsSet.lightPosition);
    });
  }

  _endTimer() => _renderTimer.cancel();

  @override
  void dispose() {
    super.dispose();
    _endTimer();
  }

  _nextObj() async {
    _changeVariantsSet.objIndex++;
    if (_changeVariantsSet.objIndex >= _objects.length) _changeVariantsSet.objIndex = 0;
    _object3DViewerController.refresh();

    Future.delayed(Duration(milliseconds: 50), () {
      _object3DViewerController.reload().then((_) {
        Future.delayed(Duration(milliseconds: 100), () {
          _object3DViewerController.refresh();
        });
      });
    });
  }

  _nextDrawMode() {
    _changeVariantsSet.drawModeIndex++;
    if (_changeVariantsSet.drawModeIndex >= _drawModes.length) _changeVariantsSet.drawModeIndex = 0;
    _object3DViewerController.reset();
    _object3DViewerController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtils.init(context);

    final changeVariantsGet = Provider.of<ChangeVariants>(context);
    final object = _objects[changeVariantsGet.objIndex];

    return Scaffold(
        backgroundColor: const Color(0xff353535),
        body: SafeArea(
            child: Stack(
          children: [
            Object3DViewer(
              lightPosition: changeVariantsGet.lightPosition,
              lightColor: object.lightColor,
              centerPivot: true,
              rasterizerMethod: changeVariantsGet.useNewAlgorithm ? RasterizerMethod.NewMethod : RasterizerMethod.OldMethod,
              gridsMaxTile: 20,
              gridsTileSize: object.gridTileSize,
              size: Size(ScreenUtils.width, ScreenUtils.height),
              object3DViewerController: _object3DViewerController,
              onHorizontalDragUpdate: (d) {
                if (changeVariantsGet.objIndex == 4)
                  _object3DViewerController.rotateY(d); //cat2
                else
                  _object3DViewerController.rotateZ(-d);
              },
              onVerticalDragUpdate: (d) {
                _object3DViewerController.rotateX(d);
              },
              initialZoom: object.zoom,
              initialAngles: object.rotation,
              objPath: object.objPath,
              texturePath: object.objTexturePath,
              drawMode: _drawModes[changeVariantsGet.drawModeIndex],
              onZoomChangeListener: (zoom) => object.zoom = zoom,
              onRotationChangeListener: (Math.Vector3 rotation) => object.rotation.setFrom(rotation),
              color: object.color,
              showInfo: true,
              showWireframe: changeVariantsGet.showWireframe,
              wireframeColor: Colors.red,
              panDistanceToActivate: 40,
            ),
            Padding(
              child: Column(
                children: <Widget>[
                  FlatButton(
                    color: Colors.white,
                    child: Text("Next obj"),
                    onPressed: () => _nextObj(),
                  ),
                  FlatButton(
                    color: Colors.white,
                    child: Text("Draw mode"),
                    onPressed: () => _nextDrawMode(),
                  ),
                  SizedBox(
                    child: CheckboxListTile(
                      title: Text("Wireframe"),
                      value: changeVariantsGet.showWireframe,
                      onChanged: (v) {
                        _changeVariantsSet.showWireframe = v;
                        _object3DViewerController.showWireframe(_changeVariantsSet.showWireframe);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    width: 200,
                  ),
                  SizedBox(
                    child: CheckboxListTile(
                      title: Text("Use new algorithm"),
                      value: changeVariantsGet.useNewAlgorithm,
                      onChanged: (v) {
                        _changeVariantsSet.useNewAlgorithm = v;
                        _object3DViewerController.useNewAlgorithm(_changeVariantsSet.useNewAlgorithm);
                      },
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
