# Flutter obj 3d Viewer/Parser/Rasterizer

An OBJ 3D Viewer and Parser for flutter/dart. Also a simple Rasterizer. 

**NO GPU, NO OPENGL-ES, only CPU side rendering via CustomPainter widget and canvas.**

## Pictures

![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p2.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p3.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p4.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p5.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p6.jpg)
![alt text](https://raw.githubusercontent.com/klaszlo8207/Flutter-OBJ-3D-Viewer/master/pix/p7.jpg)

## Video


[![Video](http://img.youtube.com/vi/q4wVxLKzqqs/0.jpg)](https://www.youtube.com/watch?v=q4wVxLKzqqs)


## Usage
```
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
```

## Example

https://github.com/klaszlo8207/Flutter-OBJ-3D-Viewer/blob/master/lib/main.dart
            
## Properties
  ```
  const Object3DViewer({
    @required this.size,    //size of the widget
    @required this.objPath, //path of the obj file, assets or sd card
    @required this.initialZoom, //initial zoom
    @required this.refreshMilliseconds, 
    @required this.animationController, //controller for the animation
    this.texturePath, //the texture path
    this.showInfo = false, //info of the obj
    this.showWireframe = false,
    this.wireframeColor = Colors.black,
    this.animateRotateX = false, //rotate and animate the model
    this.animateRotateY = false,
    this.animateRotateZ = false,
    this.initialAngles, //the initial angles
    this.drawMode = DrawMode.SHADED, //drawmode: SHADED, WIREFRAME, TEXTURED
    this.onHorizontalDragUpdate, 
    this.onVerticalDragUpdate,
    this.panDistanceToActivate, //the distance when to activate the swype
    this.onZoomChangeListener, //zoom listener
    this.onRotationChangeListener, //rotation listener
    this.color,
  });
```  
## Limits            

**Please use this library with TRIANGLES in the obj file itself.**

This library can handle some type in the obj file like: vertices, texture coordinates, normals, faces. 
It can handle negative face indices. If your model not in triangles, then you can convert that via Autodesk 3ds Max or other softwares.

Also this library can handle only a few vertices in wireframe/shaded mode (Max vertices in these modes are about 5000 vertices to get a good fps)

**In textured mode the library is in EXPERIMENTAL mode, very poor quality yet.** 
In this mode you can set fewer vertices (like a cube) and do not want to zoom in, because the fill points will be very slow because the rasterizer algorithm at the moment. 

## Author

**Kozári László** in **2020.01.06**

## License

Licensed under the Apache License, Version 2.0 (the "License")

