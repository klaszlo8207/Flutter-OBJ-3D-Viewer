# Flutter OBJ 3D Viewer

An OBJ 3D Viewer and Parser for flutter/dart. Also a simple Rasterizer. TEXTURED! LIGHTS!

**NO GPU, NO OPENGL-ES, only CPU side rendering via CustomPainter widget and canvas.**

Support me: https://www.paypal.me/LaszloKozari

## Pictures

![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p2.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p3.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p4.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p5.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p6.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p7.jpg)

## Video

[![Video](http://img.youtube.com/vi/Og3Y01Ty440/0.jpg)](https://www.youtube.com/watch?v=Og3Y01Ty440)

## Example

https://github.com/klaszlo8207/Flutter-OBJ-3D-Viewer/blob/master/lib/main.dart
            
## Properties
  ```
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
```  

## Limits            

**Please use this library with TRIANGLES in the obj file itself.**

This library can handle some type in the obj file like: vertices, texture coordinates, normals, faces. Lights, colors, textures.

It can handle negative face indices. If your model not in triangles, then you can convert that via Autodesk 3ds Max or other softwares.

Also this library can handle only a few vertices in wireframe/shaded mode (Max vertices in these modes are about 5000 vertices to get a good fps)

## Author

**Kozári László** in **2020.01.06**

## License

Licensed under the Apache License, Version 2.0 (the "License")

