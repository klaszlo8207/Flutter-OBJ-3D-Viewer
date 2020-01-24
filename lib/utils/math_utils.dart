import 'dart:core';
import 'dart:math' as Math;

import 'package:vector_math/vector_math.dart';

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

class MathUtils {
  MathUtils._();

  static Vector3 normalVector3(Vector3 v1, Vector3 v2, Vector3 v3) {
    Vector3 s1 = Vector3.copy(v2);
    s1.sub(v1);
    Vector3 s3 = Vector3.copy(v2);
    s3.sub(v3);

    return Vector3(
      (s1.y * s3.z) - (s1.z * s3.y),
      (s1.z * s3.x) - (s1.x * s3.z),
      (s1.x * s3.y) - (s1.y * s3.x),
    );
  }

  static double scalarMultiplication(Vector3 v1, Vector3 v2) => (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z);

  static double degreeToRadian(double degree) => degree * (Math.pi / 180.0);

  static double zIndex(Vector3 p1, Vector3 p2, Vector3 p3) => (p1.z + p2.z + p3.z) / 3;

  static double interpolate(double min, double max, double gradient) {
    return min + (max - min) * gradient.clamp(0, 1);
  }

  static double computeNDotL(Vector3 vertex, Vector3 normal, Vector3 lightPosition) {
    Vector3 lightDirection = lightPosition;
    lightDirection.sub(vertex);

    Vector3 normalizedNormal = new Vector3.copy(normal);
    normalizedNormal.normalize();
    Vector3 normalizedLightDirection = new Vector3.copy(lightDirection);
    normalizedLightDirection.normalize();

    return Math.max(0, normalizedNormal.dot(normalizedLightDirection));
  }
}
