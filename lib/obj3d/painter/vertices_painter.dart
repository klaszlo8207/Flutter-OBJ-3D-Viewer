import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_obj3d_test/obj3d/painter/globals.dart';
import 'package:flutter_obj3d_test/obj3d/painter/texture_data.dart';
import 'package:flutter_obj3d_test/utils/math_utils.dart';
import 'package:flutter_obj3d_test/utils/utils.dart';
import 'package:vector_math/vector_math.dart' as Math;
import 'package:flutter/rendering.dart';

//TODO draw in one
drawTexturedTriangleVertices(Canvas canvas, Math.Vector3 v1, Math.Vector3 v2, Math.Vector3 v3, Math.Vector2 uv1, Math.Vector2 uv2, Math.Vector2 uv3, Math.Vector3 n1, Math.Vector3 n2, Math.Vector3 n3, Color color, TextureData textureData, Math.Vector3 lightPosition, Color lightColor) {
  VertexMode vertexMode = VertexMode.triangles;

  if (textureData.imageUI == null) return;

  if (paintRasterizer.shader == null) {
    final TileMode tmx = TileMode.clamp;
    final TileMode tmy = TileMode.clamp;
    final Float64List matrix4 = Matrix4.identity().storage;
    final ImageShader shader = ImageShader(textureData.imageUI, tmx, tmy, matrix4);
    paintRasterizer.shader = shader;
  }

  final List<Offset> vertices = [
    gen2DPointFrom3D(v1),
    gen2DPointFrom3D(v2),
    gen2DPointFrom3D(v3),
  ];

  final List<Offset> textureCoordinates = [
    Offset(uv1.x * textureData.imageUI.width, (1 - uv1.y) * textureData.imageUI.height),
    Offset(uv2.x * textureData.imageUI.width, (1 - uv2.y) * textureData.imageUI.height),
    Offset(uv3.x * textureData.imageUI.width, (1 - uv3.y) * textureData.imageUI.height),
  ];

  double nl1 = _calculateNormal(n1, lightPosition);
  double nl2 = _calculateNormal(n2, lightPosition);
  double nl3 = _calculateNormal(n3, lightPosition);

  final shade1 = Color.lerp(color, lightColor, nl1); //color.withOpacity(nl1) + lightColor.withOpacity(1- nl1);
  final shade2 = Color.lerp(color, lightColor, nl2); //color.withOpacity(nl2) + lightColor.withOpacity(1- nl2);
  final shade3 = Color.lerp(color, lightColor, nl3); //color.withOpacity(nl3) + lightColor.withOpacity(1- nl2);

  final List<Color> colors = [shade1, shade2, shade3];
  final Vertices _vertices = Vertices(vertexMode, vertices, textureCoordinates: textureCoordinates, colors: colors);
  canvas.drawVertices(_vertices, BlendMode.colorBurn, paintRasterizer);

  /*
  final shade = Colors.black.withOpacity(brightness);
  final List<Color> colors = [shade, shade, shade];
  final Vertices _vertices = Vertices(vertexMode, vertices, textureCoordinates: textureCoordinates, colors: colors);
  canvas.drawVertices(_vertices, BlendMode.colorBurn, paintRasterizer);
  */
}

_calculateNormal(Math.Vector3 n, Math.Vector3 lightPosition) {
  Math.Vector3 normalizedLight = Math.Vector3.copy(lightPosition).normalized();
  final jnv = Math.Vector3.copy(n).normalized();
  final normal = MathUtils.scalarMultiplication(jnv, normalizedLight);
  final brightness = normal.clamp(0.1, 1.0);
  return brightness;
}
