import 'dart:io';
import 'dart:ui' as UI;

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
  IMG.Image imageIMG;
  UI.Image imageUI;
  int width;
  int height;

  load(BuildContext context,String path, {int resizeWidth}) async {
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

    imageIMG = resized;
    width = imageIMG.width;
    height = imageIMG.height;

    imageUI = await ImageLoader.loadImage(context, path);
  }

  Color map(double tu, double tv) {
    if (imageIMG == null) {
      return Colors.white;
    }
    int u = ((tu * width).toInt() % width).abs();
    int v = ((tv * height).toInt() % height).abs();

    return Color(convertABGRtoARGB(imageIMG.getPixel(u, v)));
  }
}
