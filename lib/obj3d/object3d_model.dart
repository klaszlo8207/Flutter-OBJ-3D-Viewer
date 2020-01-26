import 'dart:core';
import 'dart:ui';
import 'package:flutter_obj3d_test/utils/logger.dart';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/src/material/colors.dart' as FlutterColors;

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

class Object3DModel {
  List<Vector3> vertices;
  List<Vector3> normals;
  List<Vector2> uvs;

  List<List<int>> faceVertices;
  List<List<int>> faceNormals;
  List<List<int>> faceUVs;

  List<Color> colors;
  Map<String, Color> materials;
  bool normalizeVertices = true;
  bool centerPivot = false;

  _toRGB(double r, double g, double b) => Color.fromRGBO((r * 255).toInt(), (g * 255).toInt(), (b * 255).toInt(), 1);

  Object3DModel(bool centerPivot) {
    vertices = List<Vector3>();
    normals = List<Vector3>();
    uvs = List<Vector2>();

    faceVertices = List<List<int>>();
    faceNormals = List<List<int>>();
    faceUVs = List<List<int>>();

    colors = List<Color>();
    materials = Map();

    this.centerPivot = centerPivot;
  }

  //0 es 1 koze konvertalja a vertexeket, hogy hasonlo nagysaguak legyenek, kitoltsek a zoom-ot
  double getMultiplicationValue(double d) {
    String text = d.abs().toString();

    int integerPlaces = int.parse(text.split(".")[0]);
    String decimalPlaces = text.split(".")[1];

    if (integerPlaces > 1000)
      return 0.001;
    else if (integerPlaces > 100)
      return 0.01;
    else if (integerPlaces > 10)
      return 0.1;
    else if (integerPlaces > 1)
      return 1;
    else {
      double count = 1;
      for (int i = 0; i < decimalPlaces.length; i++) {
        var char = decimalPlaces[i];
        if (char == '0')
          count *= 10;
        else
          break;
      }
      return count;
    }
  }

  _toCenterPivot() {
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    var minZ = double.infinity;
    var maxZ = double.negativeInfinity;

    for (var i = 0; i < vertices.length; i++) {
      var vertex = vertices[i];
      if (vertex.x < minX) {
        minX = vertex.x;
      }
      if (vertex.x > maxX) {
        maxX = vertex.x;
      }
      if (vertex.y < minY) {
        minY = vertex.y;
      }
      if (vertex.y > maxY) {
        maxY = vertex.y;
      }
      if (vertex.z < minZ) {
        minZ = vertex.z;
      }
      if (vertex.z > maxZ) {
        maxZ = vertex.z;
      }
    }

    var center = Vector3(minX + (-minX + maxX) * 0.5, minY + (-minY + maxY) * 0.5, minZ + (-minZ + maxZ) * 0.5);
    var deltaVector = -center;

    for (var i = 0; i < vertices.length; i++) {
      vertices[i] += deltaVector;
    }
  }

  _parseObj(String contObj) {
    logger("-----_parseObj START");

    contObj = contObj.replaceAll("  ", " "); //remove duplicate spaces
    List<String> lines = contObj.split("\n");
    String material = "";
    int indexOfVertices = 0;
    double multiplicationValue = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // vertices
      if (line.startsWith("v ")) {
        var values = line.substring(2).split(" ");

        //normalizalunk minden vertex-et?
        if (indexOfVertices == 0 && normalizeVertices) {
          //logger("values[0] " + values[0]);
          var v = (double.parse(values[0])).abs();
          multiplicationValue = getMultiplicationValue(v);
        }
        indexOfVertices++;

        vertices.add(Vector3(
          double.parse(values[0]) * multiplicationValue,
          double.parse(values[1]) * multiplicationValue,
          double.parse(values[2]) * multiplicationValue,
        ));
      }
      // normals
      else if (line.startsWith("vn ")) {
        var values = line.substring(3).split(" ");

        normals.add(Vector3(
          double.parse(values[0]) * multiplicationValue,
          double.parse(values[1]) * multiplicationValue,
          double.parse(values[2]) * multiplicationValue,
        ));
      }
      // uvs
      else if (line.startsWith("vt ")) {
        var values = line.substring(3).split(" ");

        uvs.add(Vector2(
          double.parse(values[0]),
          double.parse(values[1]),
        ));
      }
      // materials
      else if (line.startsWith("usemtl ")) {
        material = line.substring(7).toLowerCase();
        logger("-----_parseObj usemtl $material");
      }
      // parse a face
      else if (line.startsWith("f ")) {
        final values = line.substring(2).split(" ");

        var v00 = int.parse(values[0].split("/")[0]);
        var v10 = int.parse(values[1].split("/")[0]);
        var v20 = int.parse(values[2].split("/")[0]);

        if (v00 < 0) v00 = vertices.length + v00 + 1;
        if (v10 < 0) v10 = vertices.length + v10 + 1;
        if (v20 < 0) v20 = vertices.length + v20 + 1;

        faceVertices.add(List.from([v00, v10, v20]));

        var v01 = int.parse(values[0].split("/")[1]);
        var v11 = int.parse(values[1].split("/")[1]);
        var v21 = int.parse(values[2].split("/")[1]);

        if (v01 < 0) v01 = uvs.length + v01 + 1;
        if (v11 < 0) v11 = uvs.length + v11 + 1;
        if (v21 < 0) v21 = uvs.length + v21 + 1;

        faceUVs.add(List.from([v01, v11, v21]));

        var v02 = int.parse(values[0].split("/")[2]);
        var v12 = int.parse(values[1].split("/")[2]);
        var v22 = int.parse(values[2].split("/")[2]);

        if (v02 < 0) v02 = normals.length + v02 + 1;
        if (v12 < 0) v12 = normals.length + v12 + 1;
        if (v22 < 0) v22 = normals.length + v22 + 1;

        faceNormals.add(List.from([v02, v12, v22]));

        if (material != "") {
          var color = FlutterColors.Colors.white;
          if (materials[material] != null) color = materials[material];
          colors.add(color);
          //logger("-----_parseObj color added $color");
        } else
          colors.add(FlutterColors.Colors.white);
      }
    }

    if (centerPivot) _toCenterPivot();

    logger("-----_parseObj END");
  }

  _parseMtl(String contMtl) {
    logger("-----_parseMtl START");
    var mtlName = "";
    List<String> lines = contMtl.split("\n");

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith("newmtl ")) {
        mtlName = line.split(" ")[1].toLowerCase();
        logger("-----_parseMtl newmtl found $mtlName");
      } else if (line.startsWith("Kd ")) {
        var split = line.split(" ");
        try {
          var r = double.parse(split[1]);
          var g = double.parse(split[2]);
          var b = double.parse(split[3]);

          logger("-----_parseMtl Kd found $r, $g $b");

          materials.putIfAbsent(mtlName, () => _toRGB(r, g, b));
        } catch (e) {
          materials.putIfAbsent(mtlName, () => FlutterColors.Colors.white);
        }
      }
    }
    logger("-----_parseMtl END");
  }

  parseFrom(String contObj, String contMtl) {
    _parseMtl(contMtl);
    _parseObj(contObj);
  }
}
