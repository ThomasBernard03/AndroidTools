import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AndroidVersionCard extends StatelessWidget {
  final String androidVersion;

  const AndroidVersionCard({super.key, required this.androidVersion});

  Widget androidVersionLogo(String version) {
    final basePath = "assets/android_versions/";
    switch (version) {
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
        return SvgPicture.asset("${basePath}android_5.svg");
      case "4":
        return Image(image: AssetImage('${basePath}android_4.png'));
      case "3":
        return Image(image: AssetImage('${basePath}android_3.png'));
      case "2":
        return Image(image: AssetImage('${basePath}android_1.png'));
      case "1":
        return Image(image: AssetImage('${basePath}android_1.png'));
    }

    return Image(image: AssetImage('${basePath}android.png'));
  }

  @override
  Widget build(BuildContext context) {
    final logo = androidVersionLogo(androidVersion);

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: logo,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                SizedBox(width: 128, height: 128, child: logo),
                Text(
                  "Android $androidVersion",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
