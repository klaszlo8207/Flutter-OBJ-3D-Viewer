library flutter_obj3d_viewer;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_obj3d_test/obj3d/object3d_model.dart';
import 'package:flutter_obj3d_test/obj3d/painter/scanline_painter.dart';
import 'package:flutter_obj3d_test/obj3d/painter/texture_data.dart';
import 'package:flutter_obj3d_test/utils/math_utils.dart';
import 'package:flutter_obj3d_test/utils/logger.dart';
import 'package:flutter_obj3d_test/utils/utils.dart';
import 'package:flutter_obj3d_test/widgets/zoom_gesture_detector.dart';
import 'package:flutter_obj3d_test/utils/screen_utils.dart';
import 'package:meta/meta.dart';

import 'package:vector_math/vector_math.dart' as Math;

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

const MAX_SUPPORTED_VERTICES = 16000;

class Object3DViewer extends StatefulWidget {
  final Size size;
  final String objPath;
  final String texturePath;
  final bool showInfo;
  final bool animateRotateX;
  final bool animateRotateY;
  final bool animateRotateZ;
  final bool showWireframe;
  final Color wireframeColor;
  final Math.Vector3 initialAngles;
  final DrawMode drawMode;
  final void Function(double dx) onHorizontalDragUpdate;
  final void Function(double dy) onVerticalDragUpdate;
  final Object3DViewerController animationController;
  final Function(double) onZoomChangeListener;
  final Function(Math.Vector3) onRotationChangeListener;
  final int refreshMilliseconds;
  final Color color;
  final double initialZoom;
  final int panDistanceToActivate;
  final bool centerPivot;

  currentState() => animationController.state;

  const Object3DViewer({
    @required this.size,
    @required this.objPath,
    @required this.initialZoom,
    @required this.refreshMilliseconds,
    @required this.animationController,
    this.texturePath,
    this.showInfo = false,
    this.showWireframe = false,
    this.wireframeColor = Colors.black,
    this.animateRotateX = false,
    this.animateRotateY = false,
    this.animateRotateZ = false,
    this.initialAngles,
    this.drawMode = DrawMode.SHADED,
    this.onHorizontalDragUpdate,
    this.onVerticalDragUpdate,
    this.panDistanceToActivate,
    this.onZoomChangeListener,
    this.onRotationChangeListener,
    this.color,
    this.centerPivot = false,
  });

  @override
  Object3DViewerState createState() => animationController.state;
}

enum DrawMode { WIREFRAME, SHADED, TEXTURED }

class Object3DViewerController extends StatefulWidget {
  final Object3DViewerState state = Object3DViewerState();

  reload() async => await state.reload();

  rotateX(v) => state.rotateX(v);

  rotateY(v) => state.rotateY(v);

  rotateZ(v) => state.rotateZ(v);

  @override
  State<StatefulWidget> createState() => state;
}

class Object3DViewerState extends State<Object3DViewer> {
  double angleX = 0.0;
  double angleY = 0.0;
  double angleZ = 0.0;
  double previousZoom;
  double zoom;
  Offset startingFocalPoint;
  Offset previousOffset;
  Offset offset = Offset.zero;
  Object3DModel model;
  Timer renderTimer;
  TextureData textureData;
  bool isLoading = false;
  double viewPortX = 0.0;
  double viewPortY = 0.0;

  initState() {
    super.initState();
    _init();
  }

  _init() async => _parse();

  reload() async => await _parse();

  _parse() async {
    logger("----- PARSE ${widget.objPath}");

    setState(() => isLoading = true);

    zoom = widget.initialZoom;

    if (!widget.objPath.startsWith("assets/")) {
      final pathObj = widget.objPath;
      final pathMtl = pathObj.substring(0, pathObj.length - 3) + "mtl";
      final fileObj = File(pathObj);
      final fileMtl = File(pathMtl);

      if (await fileObj.exists()) {
        final contObj = await fileObj.readAsString();
        final contMtl = (await fileMtl.exists()) ? await fileMtl.readAsString() : "";
        _newModel(contObj, contMtl);
      }
    } else {
      final cont = await rootBundle.loadString(widget.objPath);
      _newModel(cont, "");
    }

    if (widget.texturePath != null) {
      textureData = TextureData(widget.texturePath, resizeWidth: 200);
    }

    if (widget.animateRotateX || widget.animateRotateY || widget.animateRotateZ) _startRefresh();

    viewPortX = (widget.size.width / 2).toDouble();
    viewPortY = (widget.size.height / 2).toDouble();

    setState(() => isLoading = false);
  }

  _newModel(String contObj, String contMtl) {
    setState(() {
      model = Object3DModel(widget.centerPivot);
      model.parseFrom(contObj, contMtl);
    });

    if (widget.initialAngles != null) {
      setRotation(widget.initialAngles);
    }
  }

  @override
  void dispose() {
    if (widget.animateRotateX || widget.animateRotateY || widget.animateRotateZ) _endRefresh();
    super.dispose();
  }

  setRotation(Math.Vector3 r) {
    angleX = r.x;
    angleY = r.y;
    angleZ = r.z;
    setState(() {});
    if (widget.onRotationChangeListener != null) widget.onRotationChangeListener(Math.Vector3(angleX, angleY, angleZ));
  }

  rotateX(double v) {
    angleX += v;
    if (angleX > 360)
      angleX = angleX - 360;
    else if (angleX < 0) angleX = 360 - angleX;
    setState(() {});
    if (widget.onRotationChangeListener != null) widget.onRotationChangeListener(Math.Vector3(angleX, angleY, angleZ));
  }

  rotateY(double v) {
    angleY += v;
    if (angleY > 360)
      angleY = angleY - 360;
    else if (angleY < 0) angleY = 360 - angleY;
    setState(() {});
    if (widget.onRotationChangeListener != null) widget.onRotationChangeListener(Math.Vector3(angleX, angleY, angleZ));
  }

  rotateZ(double v) {
    angleZ += v;
    if (angleZ > 360)
      angleZ = angleZ - 360;
    else if (angleZ < 0) angleZ = 360 - angleZ;
    setState(() {});
    if (widget.onRotationChangeListener != null) widget.onRotationChangeListener(Math.Vector3(angleX, angleY, angleZ));
  }

  _startRefresh() {
    renderTimer = Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (widget.animateRotateX) {
        rotateY(1.2);
      }
      if (widget.animateRotateY) {
        rotateX(1.2);
      }
      if (widget.animateRotateZ) {
        rotateZ(1.2);
      }
    });
  }

  _endRefresh() => renderTimer.cancel();

  _handleScaleStart(initialFocusPoint) {
    setState(() {
      startingFocalPoint = initialFocusPoint;
      previousOffset = offset;
      previousZoom = zoom;
    });
  }

  _handleScaleUpdate(changedFocusPoint, scale) {
    setState(() {
      zoom = previousZoom * scale;
      final Offset normalizedOffset = (startingFocalPoint - previousOffset) / previousZoom;
      offset = changedFocusPoint - normalizedOffset * zoom;
      if (widget.onZoomChangeListener != null) widget.onZoomChangeListener(zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(milliseconds: widget.refreshMilliseconds), () => setState(() {}));

    if (isLoading) {
      return Center(child: CircularProgressIndicator(backgroundColor: Colors.black));
    } else {
      return ZoomGestureDetector(
        child: RepaintBoundary(
            child: CustomPaint(
          painter: Object3DRenderer(widget),
          isComplex: true,
          willChange: true,
          size: widget.size,
        )),
        onScaleStart: (initialFocusPoint) => _handleScaleStart(initialFocusPoint),
        onScaleUpdate: (changedFocusPoint, scale) => _handleScaleUpdate(changedFocusPoint, scale),
        onHorizontalDragUpdate: (double dx) => widget.onHorizontalDragUpdate(dx),
        onVerticalDragUpdate: (double dy) => widget.onVerticalDragUpdate(dy),
        panDistanceToActivate: widget.panDistanceToActivate ?? 50,
      );
    }
  }
}

var lightAngle = 0.0;
var lightPosition = Math.Vector3(20.0, 20.0, 10.0);

class Object3DRenderer extends CustomPainter {
  final stopWatch = Stopwatch();
  Paint paintFill = Paint();
  Paint paintWireframe = Paint();
  Paint paintWireframeBlue = Paint();
  final Object3DViewer widget;
  List<List<double>> depthBuffer;

  //List<Math.Vector3> indexedVertices;
  List<Math.Vector2> indexedUVs;
  List<Math.Vector3> indexedNormals;

  //List<Map<String, dynamic>> sortedItems;

  Object3DRenderer(this.widget) {
    _init();
  }

  _init() {
    paintFill.style = PaintingStyle.fill;
    paintWireframe.style = PaintingStyle.stroke;
    paintWireframe.color = widget.wireframeColor;
    paintWireframeBlue.style = PaintingStyle.stroke;
    paintWireframeBlue.color = Colors.blue;

    _clearDepthBuffer();
  }

  _drawTriangle(Canvas canvas, Math.Vector3 v1, Math.Vector3 v2, Math.Vector3 v3, Math.Vector2 uv1, Math.Vector2 uv2, Math.Vector2 uv3, Math.Vector3 n1, Math.Vector3 n2,
      Math.Vector3 n3, Color color) {
    final path = Path();
    path.moveTo(v1.x, v1.y);
    path.lineTo(v2.x, v2.y);
    path.lineTo(v3.x, v3.y);
    path.lineTo(v1.x, v1.y);
    path.close();

    final normalVector = MathUtils.normalVector3(v1, v2, v3);
    Math.Vector3 normalizedLight = Math.Vector3.copy(lightPosition).normalized();
    final jnv = Math.Vector3.copy(normalVector).normalized();
    final normal = MathUtils.scalarMultiplication(jnv, normalizedLight);
    final brightness = normal.clamp(0.1, 1.0);

    if (widget.drawMode == DrawMode.WIREFRAME) {
      drawnPointCount += 3;
      canvas.drawPath(path, paintWireframeBlue);
    } else if (widget.drawMode == DrawMode.SHADED) {
      drawnPointCount += 3;
      final r = (brightness * color.red).toInt();
      final g = (brightness * color.green).toInt();
      final b = (brightness * color.blue).toInt();
      paintFill.color = Color.fromARGB(255, r, g, b);
      canvas.drawPath(path, paintFill);
    } else if (widget.drawMode == DrawMode.TEXTURED) {
      drawFilledTriangle(canvas, depthBuffer, v1, v2, v3, uv1, uv2, uv3, n1, n2, n3, color, brightness, widget.currentState().textureData, lightPosition);
    }

    if (widget.showWireframe) {
      canvas.drawPath(path, paintWireframe);
      drawnPointCount += 3;
    }
  }

  _clearDepthBuffer() {
    drawnPointCount = 0;
    depthBuffer = List.generate(widget.size.width.toInt(), (_) => new List.filled(widget.size.height.toInt(), double.maxFinite));
  }

  _transformVertex(Math.Vector3 vertex) {
    final _viewPortX = (widget.size.width / 2).toDouble();
    final _viewPortY = (widget.size.height / 2).toDouble();

    final trans = Math.Matrix4.translationValues(_viewPortX, _viewPortY, 1);
    trans.scale(widget.currentState().zoom, -widget.currentState().zoom);
    trans.rotateX(MathUtils.degreeToRadian(widget.currentState().angleX));
    trans.rotateY(MathUtils.degreeToRadian(widget.currentState().angleY));
    trans.rotateZ(MathUtils.degreeToRadian(widget.currentState().angleZ));
    return trans.transform3(vertex);
  }

  @override
  void paint(Canvas canvas, Size size) {
    stopWatch.start();

    final model = widget.currentState().model;

    if (model.vertices.length > MAX_SUPPORTED_VERTICES) {
      final sHead = "${widget.objPath}";
      final sDesc = "Too much vertices: ${model.vertices.length}! Max supported vertices: $MAX_SUPPORTED_VERTICES";
      drawErrorText(canvas, sHead, sDesc);

      return;
    }

    _clearDepthBuffer();

    final d = 25.0;
    lightAngle += 0.8;
    if (lightAngle > 360) lightAngle = 0;
    double fx = sin(Math.radians(lightAngle)) * d;
    double fz = cos(Math.radians(lightAngle)) * d;
    lightPosition.setValues(fx, d, fz);

    //
    final indexedVertices = List<Math.Vector3>();
    for (int i = 0; i < model.faceVertices.length; i++) {
      final face = model.faceVertices[i];
      final f0 = face[0] - 1;
      final f1 = face[1] - 1;
      final f2 = face[2] - 1;

      final v1 = _transformVertex(Math.Vector3.copy(model.vertices[f0]));
      final v2 = _transformVertex(Math.Vector3.copy(model.vertices[f1]));
      final v3 = _transformVertex(Math.Vector3.copy(model.vertices[f2]));

      indexedVertices.add(v1);
      indexedVertices.add(v2);
      indexedVertices.add(v3);
    }

    if (indexedUVs == null) {
      indexedUVs = List();
      for (int i = 0; i < model.faceUVs.length; i++) {
        final face = model.faceUVs[i];
        final f0 = face[0] - 1;
        final f1 = face[1] - 1;
        final f2 = face[2] - 1;

        final uv1 = model.uvs[f0];
        final uv2 = model.uvs[f1];
        final uv3 = model.uvs[f2];

        indexedUVs.add(uv1);
        indexedUVs.add(uv2);
        indexedUVs.add(uv3);
      }
    }

    if (indexedNormals == null) {
      indexedNormals = List();
      for (int i = 0; i < model.faceNormals.length; i++) {
        final face = model.faceNormals[i];
        final f0 = face[0] - 1;
        final f1 = face[1] - 1;
        final f2 = face[2] - 1;

        final n1 = model.normals[f0];
        final n2 = model.normals[f1];
        final n3 = model.normals[f2];

        indexedNormals.add(n1);
        indexedNormals.add(n2);
        indexedNormals.add(n3);
      }
    }

    final sortedItems = List<Map<String, dynamic>>();
    for (var i = 0; i < indexedVertices.length; i += 3) {
      final v1 = indexedVertices[i];
      final v2 = indexedVertices[i + 1];
      final v3 = indexedVertices[i + 2];

      final uv1 = indexedUVs[i];
      final uv2 = indexedUVs[i + 1];
      final uv3 = indexedUVs[i + 2];

      final n1 = indexedNormals[i];
      final n2 = indexedNormals[i + 1];
      final n3 = indexedNormals[i + 2];

      sortedItems.add({
        "index": i,
        "order": MathUtils.zIndex(v1, v2, v3),
        "v1": v1,
        "v2": v2,
        "v3": v3,
        "uv1": uv1,
        "uv2": uv2,
        "uv3": uv3,
        "n1": n1,
        "n2": n2,
        "n3": n3,
      });
    }
    sortedItems.sort((Map a, Map b) => a["order"].compareTo(b["order"]));
    //

    for (int i = 0; i < sortedItems.length; i++) {
      final sorted = sortedItems[i];
      final v1 = Math.Vector3.copy(sorted['v1']);
      final v2 = Math.Vector3.copy(sorted['v2']);
      final v3 = Math.Vector3.copy(sorted['v3']);
      final uv1 = sorted['uv1'];
      final uv2 = sorted['uv2'];
      final uv3 = sorted['uv3'];
      final n1 = sorted['n1'];
      final n2 = sorted['n2'];
      final n3 = sorted['n3'];

      _drawTriangle(canvas, v1, v2, v3, uv1, uv2, uv3, n1, n2, n3, widget.color);
    }

    _drawInfo(canvas, sortedItems.length);

    stopWatch.stop();
  }

  _drawInfo(Canvas canvas, int verticesCount) {
    if (widget.showInfo) {
      drawText(canvas, "verts: " + verticesCount.toString() + " points: $drawnPointCount", Offset(20, ScreenUtils.height - 120), fontSize: 15);
      String fps = (1000 / stopWatch.elapsed.inMilliseconds).toStringAsFixed(0);
      drawText(canvas, "fps: " + fps + "  zoom: " + widget.currentState().zoom.toStringAsFixed(1), Offset(20, ScreenUtils.height - 100));
      drawText(canvas, "path: " + widget.objPath, Offset(20, ScreenUtils.height - 145), fontSize: 12);
    }
  }

  @override
  bool shouldRepaint(Object3DRenderer old) => true;
}
