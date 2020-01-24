import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_obj3d_test/utils/utils.dart';

import 'package:image/image.dart' as IMG;

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

class TextureData {
  IMG.Image image;
  int width;
  int height;

  TextureData(String path, {int resizeWidth = 120}) {
    _load(path, resizeWidth: resizeWidth);
  }

  _load(String path, {int resizeWidth}) async {
    ByteData imageData;

    if (path.startsWith("assets/"))
      imageData = await rootBundle.load(path);
    else {
      final fileImg = File(path);
      if (await fileImg.exists()) {
        imageData = ByteData.view((await fileImg.readAsBytes()).buffer);
      }
    }

    final buffer = imageData.buffer;
    final imageInBytes = buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes);
    IMG.Image resized = IMG.copyResize(IMG.decodeImage(imageInBytes), width: resizeWidth);
    image = resized;
    width = image.width;
    height = image.height;
  }

  Color map(double tu, double tv) {
    if (image == null) {
      return Colors.white;
    }
    int u = ((tu * width).toInt() % width).abs();
    int v = ((tv * height).toInt() % height).abs();

    return Color(convertABGRtoARGB(image.getPixel(u, v)));
  }
}
