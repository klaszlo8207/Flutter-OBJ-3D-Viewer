library flutter_obj3d_viewer;

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_obj3d_test/obj3d/object3d_model.dart';
import 'package:flutter_obj3d_test/obj3d/painter/globals.dart';
import 'package:flutter_obj3d_test/obj3d/painter/scanline_painter.dart';
import 'package:flutter_obj3d_test/obj3d/painter/texture_data.dart';
import 'package:flutter_obj3d_test/obj3d/painter/vertices_painter.dart';
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

class Object3DViewer extends StatefulWidget {
  final Size size;
  final String objPath;
  final String texturePath;
  final bool showInfo;
  final Math.Vector3 initialAngles;
  final DrawMode drawMode;
  final void Function(double dx) onHorizontalDragUpdate;
  final void Function(double dy) onVerticalDragUpdate;
  final Object3DViewerController object3DViewerController;
  final Function(double) onZoomChangeListener;
  final Function(Math.Vector3) onRotationChangeListener;
  final Color color;
  final double initialZoom;
  final int panDistanceToActivate;
  final bool centerPivot;
  final bool showGrids;
  final Color gridsColor;
  final int gridsMaxTile;
  final double gridsTileSize;
  RasterizerMethod rasterizerMethod;
  bool showWireframe;
  Color wireframeColor;
  Math.Vector3 lightPosition;
  final Color backgroundColor;
  final Color lightColor;

  currentState() => object3DViewerController.state;

  Object3DViewer({
    @required this.size,
    @required this.objPath,
    @required this.initialZoom,
    @required this.object3DViewerController,
    @required this.lightPosition,
    this.backgroundColor = const Color(0xff353535),
    this.texturePath,
    this.showInfo,
    this.showWireframe,
    this.wireframeColor = Colors.black,
    this.initialAngles,
    this.drawMode = DrawMode.SHADED,
    this.onHorizontalDragUpdate,
    this.onVerticalDragUpdate,
    this.panDistanceToActivate,
    this.onZoomChangeListener,
    this.onRotationChangeListener,
    this.color = Colors.black,
    this.centerPivot = false,
    this.showGrids = true,
    this.gridsColor = const Color(0xff4b4b4b),
    this.gridsMaxTile = 10,
    this.gridsTileSize = 1.0,
    this.rasterizerMethod = RasterizerMethod.NewMethod,
    this.lightColor = Colors.white,
  });

  @override
  Object3DViewerState createState() => object3DViewerController.state;
}

enum DrawMode { WIREFRAME, SHADED, TEXTURED }

enum RasterizerMethod { OldMethod, NewMethod }

class Object3DViewerController extends StatefulWidget {
  final Object3DViewerState state = Object3DViewerState();

  reload() async => await state.reload();

  rotateX(v) => state.rotateX(v);

  rotateY(v) => state.rotateY(v);

  rotateZ(v) => state.rotateZ(v);

  reset() => state.reset();

  refresh() {
    if (state.object3DRenderer != null) state.object3DRenderer.refresh();
  }

  @override
  State<StatefulWidget> createState() => state;

  setLightPosition(Math.Vector3 lightPosition) => state.setLightPosition(lightPosition);

  showWireframe(bool showWireframe) => state.showWireframe(showWireframe);

  useNewAlgorithm(bool useNewAlgorithm) => state.useNewAlgorithm(useNewAlgorithm);

  getWidget() => state.widget;
}

class Object3DViewerState extends State<Object3DViewer> {
  double angleX = 0.0;
  double angleY = 0.0;
  double angleZ = 0.0;
  double previousZoom;
  double zoom;
  var rotation = Math.Vector3(0, 0, 0);
  Offset startingFocalPoint;
  Offset previousOffset;
  Offset offset = Offset.zero;
  Object3DModel model;
  TextureData textureData;
  bool isLoading = false;
  double viewPortX = 0.0;
  double viewPortY = 0.0;
  Object3DRenderer object3DRenderer;

  initState() {
    super.initState();
    _init();
  }

  _init() async => _parse();

  reload() async => await _parse();

  reset() async => object3DRenderer = null;

  _parse() async {
    logger("----- PARSE ${widget.objPath}");

    setState(() => isLoading = true);

    object3DRenderer = null;
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
      textureData = TextureData();
      await textureData.load(context, widget.texturePath, resizeWidth: 200);
    }

    viewPortX = (widget.size.width / 2).toDouble();
    viewPortY = (widget.size.height / 2).toDouble();

    paintRasterizer.shader = null;

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
    super.dispose();
  }

  setRotation(Math.Vector3 r) {
    angleX = r.x;
    angleY = r.y;
    angleZ = r.z;
    _rotationChanged();
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  rotateX(double v) {
    angleX += v;
    if (angleX > 360)
      angleX = angleX - 360;
    else if (angleX < 0) angleX = 360 - angleX;
    _rotationChanged();
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  rotateY(double v) {
    angleY += v;
    if (angleY > 360)
      angleY = angleY - 360;
    else if (angleY < 0) angleY = 360 - angleY;
    _rotationChanged();
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  rotateZ(double v) {
    angleZ += v;
    if (angleZ > 360)
      angleZ = angleZ - 360;
    else if (angleZ < 0) angleZ = 360 - angleZ;
    _rotationChanged();
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  _rotationChanged() {
    rotation.setValues(angleX, angleY, angleZ);
    if (widget.onRotationChangeListener != null) widget.onRotationChangeListener(rotation);
  }

  _handleScaleStart(initialFocusPoint) {
    startingFocalPoint = initialFocusPoint;
    previousOffset = offset;
    previousZoom = zoom;
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  _handleScaleUpdate(changedFocusPoint, scale) {
    zoom = previousZoom * scale;
    final Offset normalizedOffset = (startingFocalPoint - previousOffset) / previousZoom;
    offset = changedFocusPoint - normalizedOffset * zoom;
    if (widget.onZoomChangeListener != null) widget.onZoomChangeListener(zoom);
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(backgroundColor: Colors.black));
    } else {
      if (object3DRenderer == null) {
        object3DRenderer = Object3DRenderer(widget);
        object3DRenderer.refresh();
      }

      return ZoomGestureDetector(
        child: RepaintBoundary(
            child: CustomPaint(
          painter: object3DRenderer,
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

  setLightPosition(Math.Vector3 lightPosition) {
    widget.lightPosition = lightPosition;
    if (object3DRenderer != null) object3DRenderer.refresh();
  }

  showWireframe(bool showWireframe) {
    widget.showWireframe = showWireframe;

    if (object3DRenderer != null) {
      object3DRenderer.reset();
      Future.delayed(Duration(milliseconds: 100), () {
        object3DRenderer.refresh();
      });
    }
  }

  useNewAlgorithm(bool useNewAlgorithm) {
    widget.rasterizerMethod = useNewAlgorithm ? RasterizerMethod.NewMethod : RasterizerMethod.OldMethod;

    if (object3DRenderer != null) {
      object3DRenderer.reset();
      Future.delayed(Duration(milliseconds: 100), () {
        object3DRenderer.refresh();
      });
    }
  }
}

class Object3DRenderer extends ChangeNotifier implements CustomPainter {
  Paint paintFill = Paint();
  Paint paintWireframe = Paint();
  Paint paintWireframeBlue = Paint();
  Paint paintGrids = Paint();
  Paint paintGridsMain = Paint();
  Paint paintBackground = Paint();
  final Object3DViewer widget;
  List<List<double>> depthBuffer;
  List<Math.Vector2> indexedUVs;
  List<Math.Vector3> indexedNormals;

  Object3DRenderer(this.widget) {
    _init();
  }

  _init() {
    paintFill.style = PaintingStyle.fill;
    paintWireframe.style = PaintingStyle.stroke;
    paintWireframe.color = widget.wireframeColor;
    paintWireframeBlue.style = PaintingStyle.stroke;
    paintWireframeBlue.color = Colors.blue;
    paintGrids.style = PaintingStyle.stroke;
    paintGrids.color = widget.gridsColor;
    paintGridsMain.style = PaintingStyle.stroke;
    paintGridsMain.color = Colors.black;
    paintGridsMain.strokeWidth = 1;
    paintBackground.color = widget.backgroundColor;

    _clearDepthBuffer();
  }

  _drawTriangle(
      Canvas canvas, Math.Vector3 v1, Math.Vector3 v2, Math.Vector3 v3, Math.Vector2 uv1, Math.Vector2 uv2, Math.Vector2 uv3, Math.Vector3 n1, Math.Vector3 n2, Math.Vector3 n3) {
    final path = Path();
    path.moveTo(v1.x, v1.y);
    path.lineTo(v2.x, v2.y);
    path.lineTo(v3.x, v3.y);
    path.lineTo(v1.x, v1.y);
    path.close();

    final color = widget.color;
    final lightPosition = widget.lightPosition;
    final lightColor = widget.lightColor;

    final normalVector = MathUtils.normalVector3(v1, v2, v3);
    Math.Vector3 normalizedLight = Math.Vector3.copy(lightPosition).normalized();
    final jnv = Math.Vector3.copy(normalVector).normalized();
    final normal = MathUtils.scalarMultiplication(jnv, normalizedLight);
    final brightness = normal.clamp(0.1, 1.0);

    if (widget.drawMode == DrawMode.WIREFRAME) {
      canvas.drawPath(path, paintWireframeBlue);
    } else if (widget.drawMode == DrawMode.SHADED) {
      final shade = Color.lerp(color, lightColor, brightness);
      paintFill.color = shade;
      canvas.drawPath(path, paintFill);
    } else if (widget.drawMode == DrawMode.TEXTURED) {
      if (widget.rasterizerMethod == RasterizerMethod.OldMethod)
        drawTexturedTrianglePoints(canvas, depthBuffer, v1, v2, v3, uv1, uv2, uv3, n1, n2, n3, color, brightness, widget.currentState().textureData, lightPosition);
      else if (widget.rasterizerMethod == RasterizerMethod.NewMethod)
        drawTexturedTriangleVertices(canvas, v1, v2, v3, uv1, uv2, uv3, n1, n2, n3, color, widget.currentState().textureData, lightPosition, lightColor);
    }

    if (widget.showWireframe ?? false == true) {
      canvas.drawPath(path, paintWireframe);
    }
  }

  _clearDepthBuffer() {
    depthBuffer = List.generate(widget.size.width.toInt(), (_) => List.filled(widget.size.height.toInt(), double.maxFinite));
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

  _drawGrids(Canvas canvas) {
    final steps = widget.gridsTileSize;
    final distance = (widget.gridsMaxTile * steps).toInt();

    for (int i = -distance ~/ steps; i <= distance ~/ steps; i++) {
      final p1 = gen2DPointFrom3D(_transformVertex(Math.Vector3(-distance.toDouble(), 0, -i * steps.toDouble())));
      final p2 = gen2DPointFrom3D(_transformVertex(Math.Vector3(distance.toDouble(), 0, -i * steps.toDouble())));
      canvas.drawLine(p1, p2, paintGrids);

      final p3 = gen2DPointFrom3D(_transformVertex(Math.Vector3(-distance.toDouble(), 0, i * steps.toDouble())));
      final p4 = gen2DPointFrom3D(_transformVertex(Math.Vector3(distance.toDouble(), 0, i * steps.toDouble())));
      canvas.drawLine(p3, p4, paintGrids);

      if (i == 0) {
        canvas.drawLine(p1, p2, paintGridsMain);
      }
    }

    for (int i = -distance ~/ steps; i <= distance ~/ steps; i++) {
      final p1 = gen2DPointFrom3D(_transformVertex(Math.Vector3(-i * steps.toDouble(), 0, -distance.toDouble())));
      final p2 = gen2DPointFrom3D(_transformVertex(Math.Vector3(-i * steps.toDouble(), 0, distance.toDouble())));
      canvas.drawLine(p1, p2, paintGrids);

      final p3 = gen2DPointFrom3D(_transformVertex(Math.Vector3(i * steps.toDouble(), 0, -distance.toDouble())));
      final p4 = gen2DPointFrom3D(_transformVertex(Math.Vector3(i * steps.toDouble(), 0, distance.toDouble())));
      canvas.drawLine(p3, p4, paintGrids);

      if (i == 0) {
        canvas.drawLine(p1, p2, paintGridsMain);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(paintBackground);

    if (widget.showGrids) {
      _drawGrids(canvas);
    }

    final model = widget.currentState().model;

    if (model.vertices.length > MAX_SUPPORTED_VERTICES) {
      final sHead = "${widget.objPath}";
      final sDesc = "Too much points: ${model.vertices.length}! Max supported points: $MAX_SUPPORTED_VERTICES";
      drawErrorText(canvas, sHead, sDesc);

      return;
    }

    _clearDepthBuffer();

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

      _drawTriangle(canvas, v1, v2, v3, uv1, uv2, uv3, n1, n2, n3);
    }

    _drawInfo(canvas, sortedItems.length);
  }

  _drawInfo(Canvas canvas, int verticesCount) {
    if (widget.showInfo) {
      final rot = widget.currentState().rotation;
      final zoom = widget.currentState().zoom.toStringAsFixed(1);

      drawText(canvas, "verts: " + verticesCount.toString(), Offset(20, ScreenUtils.height - 130), fontSize: 14);

      drawText(canvas, "zoom: " + zoom + " rot: (" + rot.x.toStringAsFixed(0) + ", " + rot.y.toStringAsFixed(0) + ", " + rot.z.toStringAsFixed(0) + ")",
          Offset(20, ScreenUtils.height - 110),
          fontSize: 14);

      drawText(canvas, "path: " + widget.objPath, Offset(20, ScreenUtils.height - 160), fontSize: 12);
    }
  }

  refresh() => notifyListeners();

  reset() {
    if (widget.object3DViewerController != null) widget.object3DViewerController.reset();
  }

  @override
  bool shouldRepaint(Object3DRenderer old) => true;

  @override
  bool hitTest(Offset position) => true;

  @override
  bool shouldRebuildSemantics(CustomPainter previous) => false;

  @override
  get semanticsBuilder => null;

}
