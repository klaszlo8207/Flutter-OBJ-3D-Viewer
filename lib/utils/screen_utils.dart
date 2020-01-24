import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///
/// Created by Kozári László in 2020.01.06
/// lostinwar22@gmail.com
///

class ScreenUtils {
  ScreenUtils._();

  static double width = 1;
  static double height = 1;

  static init(BuildContext context) {
    var size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
  }

}