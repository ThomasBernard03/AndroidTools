import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

extension StringExtensions on String {
  String anonymize() {
    if (length <= 6) {
      return '***';
    }

    final start = substring(0, 3);
    final end = substring(length - 3);

    return '$start...$end';
  }

  Widget androidVersionLogo() {
    final basePath = "assets/android_versions/";
    switch (this) {
      case "16":
        return SvgPicture.asset("${basePath}android_16.svg");
      case "15":
        return SvgPicture.asset("${basePath}android_15.svg");
      case "14":
        return SvgPicture.asset("${basePath}android_14.svg");
      case "13":
        return SvgPicture.asset("${basePath}android_13.svg");
      case "12":
        return SvgPicture.asset("${basePath}android_12.svg");
      case "11":
        return SvgPicture.asset("${basePath}android_11.svg");
      case "10":
        return SvgPicture.asset("${basePath}android_10.svg");
      case "9":
        return SvgPicture.asset("${basePath}android_9.svg");
      case "8":
        return SvgPicture.asset("${basePath}android_8.svg");
      case "7":
        return Image(image: AssetImage('${basePath}android_7.png'));
      case "6":
        return SvgPicture.asset("${basePath}android_6.svg");
      case "5":
        return SvgPicture.asset("${basePath}android_.svg");
      case "4":
        return Image(image: AssetImage('${basePath}android_4.png'));
      case "3":
        return Image(image: AssetImage('${basePath}android_3.png'));
      case "2":
        return Image(image: AssetImage('${basePath}android_2.png'));
      case "1":
        return Image(image: AssetImage('${basePath}android_1.png'));
    }

    return Icon(Icons.android);
  }
}
