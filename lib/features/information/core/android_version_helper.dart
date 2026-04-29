import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Returns the appropriate Android version logo widget based on the version string.
Widget getAndroidVersionLogo(String version, {double? size}) {
  const basePath = "assets/android_versions/";

  Widget logo;
  switch (version) {
    case "17":
      logo = SvgPicture.asset("${basePath}android_17.svg");
    case "16":
      logo = SvgPicture.asset("${basePath}android_16.svg");
      break;
    case "15":
      logo = SvgPicture.asset("${basePath}android_15.svg");
      break;
    case "14":
      logo = SvgPicture.asset("${basePath}android_14.svg");
      break;
    case "13":
      logo = SvgPicture.asset("${basePath}android_13.svg");
      break;
    case "12":
      logo = SvgPicture.asset("${basePath}android_12.svg");
      break;
    case "11":
      logo = SvgPicture.asset("${basePath}android_11.svg");
      break;
    case "10":
      logo = SvgPicture.asset("${basePath}android_10.svg");
      break;
    case "9":
      logo = SvgPicture.asset("${basePath}android_9.svg");
      break;
    case "8":
      logo = SvgPicture.asset("${basePath}android_8.svg");
      break;
    case "7":
      logo = const Image(image: AssetImage('${basePath}android_7.png'));
      break;
    case "6":
      logo = SvgPicture.asset("${basePath}android_6.svg");
      break;
    case "5":
      logo = SvgPicture.asset("${basePath}android_5.svg");
      break;
    case "4":
      logo = const Image(image: AssetImage('${basePath}android_4.png'));
      break;
    case "3":
      logo = const Image(image: AssetImage('${basePath}android_3.png'));
      break;
    case "2":
      logo = const Image(image: AssetImage('${basePath}android_1.png'));
      break;
    case "1":
      logo = const Image(image: AssetImage('${basePath}android_1.png'));
      break;
    default:
      logo = const Image(image: AssetImage('${basePath}android.png'));
  }

  if (size != null) {
    return SizedBox(width: size, height: size, child: logo);
  }

  return logo;
}
