import 'package:flutter/material.dart';

class DevicePreview extends StatelessWidget {
  final String version;

  const DevicePreview({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/pixels/pixel_android_$version.png",
      height: 400,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset("assets/pixels/pixel_android.png", height: 400),
    );
  }
}
