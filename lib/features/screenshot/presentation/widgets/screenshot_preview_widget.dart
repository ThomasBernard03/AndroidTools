import 'dart:io';

import 'package:flutter/material.dart';

class ScreenshotPreviewWidget extends StatelessWidget {
  final String imagePath;

  const ScreenshotPreviewWidget({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(imagePath),
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load screenshot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
