import 'dart:ui';

import 'package:android_tools/shared/core/string_extensions.dart';
import 'package:flutter/material.dart';

class AndroidVersionCard extends StatelessWidget {
  final String androidVersion;

  const AndroidVersionCard({super.key, required this.androidVersion});

  @override
  Widget build(BuildContext context) {
    final logo = androidVersion.androidVersionLogo();

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
