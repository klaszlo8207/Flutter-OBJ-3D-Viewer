import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_obj3d_test/obj3d/painter/scanline_data.dart';
import 'package:flutter_obj3d_test/obj3d/painter/texture_data.dart';
import 'package:flutter_obj3d_test/utils/math_utils.dart';
import 'package:vector_math/vector_math.dart' as Math;

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

void drawFilledTriangle(
  Canvas canvas,
  List<List<double>> depthBuffer,
  Math.Vector3 v1,
  Math.Vector3 v2,
  Math.Vector3 v3,
  Math.Vector2 uv1,
  Math.Vector2 uv2,
  Math.Vector2 uv3,
  Math.Vector3 n1,
  Math.Vector3 n2,
  Math.Vector3 n3,
  Color color,
  double brightness,
  TextureData texture,
  Math.Vector3 lightPosition,
) {
  // Sorting the points in order to always have this order on screen p1, p2 & p3
  // with p1 always up (thus having the Y the lowest possible to be near the top screen)
  // then p2 between p1 & p3
  if (v1.y > v2.y) {
    Math.Vector3 temp = v2;
    v2 = v1;
    v1 = temp;
  }

  if (v2.y > v3.y) {
    Math.Vector3 temp = v2;
    v2 = v3;
    v3 = temp;
  }

  if (v1.y > v2.y) {
    Math.Vector3 temp = v2;
    v2 = v1;
    v1 = temp;
  }

  Math.Vector3 p1 = v1;
  Math.Vector3 p2 = v2;
  Math.Vector3 p3 = v3;

  // Computing the cos of the angle between the light vector and the normal vector
  // it will return a value between 0 and 1 that will be used as the intensity of the color
  /*
  double nl1 = MathUtils.computeNDotL(v1, n1, lightPos);
  double nl2 = MathUtils.computeNDotL(v2, n2, lightPos);
  double nl3 = MathUtils.computeNDotL(v3, n3, lightPos);
  //double nl3 = MathUtils.computeNDotL(v3, v3.getNormal(), lightPos);

   */

  ScanLineData data = new ScanLineData();

  // Lines' directions
  double dP1P2, dP1P3;

  // http://en.wikipedia.org/wiki/Slope
  // Computing inverse slopes
  if (p2.y - p1.y > 0) {
    dP1P2 = ((p2.x - p1.x) / (p2.y - p1.y));
  } else {
    dP1P2 = 0;
  }

  if (p3.y - p1.y > 0) {
    dP1P3 = ((p3.x - p1.x) / (p3.y - p1.y));
  } else {
    dP1P3 = 0;
  }

  // First case where triangles are like that: P1-P2(right)-P3 (from top to bottom)
  if (dP1P2 > dP1P3) {
    for (int y = p1.y.toInt(); y <= p3.y.toInt(); y++) {
      data.setCurrentY(y);
      if (y < p2.y) {
        /*
        data.setNdotla(nl1);
        data.setNdotlb(nl3);
        data.setNdotlc(nl1);
        data.setNdotld(nl2);

         */

        if (texture != null) {
          data.setUa(uv1.x);
          data.setUb(uv3.x);
          data.setUc(uv1.x);
          data.setUd(uv2.x);

          data.setVa(uv1.y);
          data.setVb(uv3.y);
          data.setVc(uv1.y);
          data.setVd(uv2.y);
        }

        processScanLine(canvas, depthBuffer, data, v1, v3, v1, v2, color, brightness, texture);
      } else {
        /*
        data.setNdotla(nl1);
        data.setNdotlb(nl3);
        data.setNdotlc(nl2);
        data.setNdotld(nl3);
         */

        if (texture != null) {
          data.setUa(uv1.x);
          data.setUb(uv3.x);
          data.setUc(uv2.x);
          data.setUd(uv3.x);

          data.setVa(uv1.y);
          data.setVb(uv3.y);
          data.setVc(uv2.y);
          data.setVd(uv3.y);
        }

        processScanLine(canvas, depthBuffer, data, v1, v3, v2, v3, color, brightness, texture);
      }
    }
  } else {
    // Second case where triangles are like that: P1-P2(left)-P3 (from top to bottom)
    for (int y = p1.y.toInt(); y <= p3.y.toInt(); y++) {
      data.setCurrentY(y);
      if (y < p2.y) {
        /*
        data.setNdotla(nl1);
        data.setNdotlb(nl2);
        data.setNdotlc(nl1);
        data.setNdotld(nl3);
         */

        if (texture != null) {
          data.setUa(uv1.x);
          data.setUb(uv2.x);
          data.setUc(uv1.x);
          data.setUd(uv3.x);

          data.setVa(uv1.y);
          data.setVb(uv2.y);
          data.setVc(uv1.y);
          data.setVd(uv3.y);
        }
        processScanLine(canvas, depthBuffer, data, v1, v2, v1, v3, color, brightness, texture);
      } else {
        /*
        data.setNdotla(nl2);
        data.setNdotlb(nl3);
        data.setNdotlc(nl1);
        data.setNdotld(nl3);
         */

        if (texture != null) {
          data.setUa(uv2.x);
          data.setUb(uv3.x);
          data.setUc(uv1.x);
          data.setUd(uv3.x);

          data.setVa(uv2.y);
          data.setVb(uv3.y);
          data.setVc(uv1.y);
          data.setVd(uv3.y);
        }
        processScanLine(canvas, depthBuffer, data, v2, v3, v1, v3, color, brightness, texture);
      }
    }
  }
}

/// Drawing line between 2 points from left to right.
/// papb -> pcpd
/// pa, pb, pc, pd must then be sorted before.
void processScanLine(
  Canvas canvas,
  List<List<double>> depthBuffer,
  ScanLineData data,
  Math.Vector3 va,
  Math.Vector3 vb,
  Math.Vector3 vc,
  Math.Vector3 vd,
  Color color,
  double brightness,
  TextureData texture,
) {
  Math.Vector3 pa = va;
  Math.Vector3 pb = vb;
  Math.Vector3 pc = vc;
  Math.Vector3 pd = vd;

  // Thanks to current Y, we can compute the gradient to compute others values like
  // the starting X (sx) and ending X (ex) to draw between
  // if pa.Y == pb.Y or pc.Y == pd.Y, gradient is forced to 1
  double gradient1 = pa.y != pb.y ? ((data.getCurrentY() - pa.y) / (pb.y - pa.y)) : 1;
  double gradient2 = pc.y != pd.y ? ((data.getCurrentY() - pc.y) / (pd.y - pc.y)) : 1;

  // Starting X & ending X
  int sx = MathUtils.interpolate(pa.x, pb.x, gradient1).toInt();
  int ex = MathUtils.interpolate(pc.x, pd.x, gradient2).toInt();
  // Starting Z & ending Z
  double z1 = MathUtils.interpolate(pa.z, pb.z, gradient1);
  double z2 = MathUtils.interpolate(pc.z, pd.z, gradient2);

  // Starting and ending of color gradient
  //double snl = MathUtils.interpolate(data.getNdotla(), data.getNdotlb(), gradient1);
  //double enl = MathUtils.interpolate(data.getNdotlc(), data.getNdotld(), gradient2);

  // Interpolating texture coordinates on Y
  double su = 0, eu = 0, sv = 0, ev = 0;

  if (texture != null) {
    su = MathUtils.interpolate(data.getUa(), data.getUb(), gradient1);
    eu = MathUtils.interpolate(data.getUc(), data.getUd(), gradient2);
    sv = MathUtils.interpolate(data.getVa(), data.getVb(), gradient1);
    ev = MathUtils.interpolate(data.getVc(), data.getVd(), gradient2);
  }

  // Drawing a line from left (sx) to right (ex)
  for (int x = sx; x < ex; x++) {
    double gradient = (x - sx) / (ex - sx);
    double z = MathUtils.interpolate(z1, z2, gradient);

    // Color according to light
    //double ndotl = MathUtils.interpolate(snl, enl, gradient);

    double r = color.red.toDouble(); //* ndotl;
    double g = color.green.toDouble(); // * ndotl;
    double b = color.blue.toDouble(); //* ndotl;
    // Texture
    double u, v;

    if (texture != null) {
      u = MathUtils.interpolate(su, eu, gradient);
      v = MathUtils.interpolate(sv, ev, gradient);

      Color textureColor = texture.map(u, v);

      r = (textureColor.red / 255);
      g = (textureColor.green / 255);
      b = (textureColor.blue / 255);
    }

    final rn = (brightness * r);
    final gn = (brightness * g);
    final bn = (brightness * b);

    Color rgb = Color.fromARGB(255, (rn * 255).toInt(), (gn * 255).toInt(), (bn * 255).toInt());

    // Draw point only if it is visible (Z-Buffering)
    try {
      if (depthBuffer[x][data.getCurrentY()] >= z) {
        depthBuffer[x][data.getCurrentY()] = z;
        _drawPoint(canvas, new Math.Vector3(x.toDouble(), data.getCurrentY().toDouble(), z), rgb, u, v);
      }
    } catch (e) {}
  }
}

final Paint paintRasterizer = Paint();
int drawnPointCount = 0;

_drawPoint(Canvas canvas, Math.Vector3 v, Color c, double s, double t) {
  paintRasterizer.style = PaintingStyle.stroke;
  paintRasterizer.strokeWidth = 1;
  paintRasterizer.color = c;

  final points = [Offset(v.x.toDouble(), v.y.toDouble())];
  canvas.drawPoints(PointMode.points, points, paintRasterizer);

  drawnPointCount++;
}
