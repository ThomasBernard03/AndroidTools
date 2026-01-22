import 'package:android_tools/features/file_explorer/core/int_extensions.dart';
import 'package:android_tools/features/information/presentation/widgets/bubble_progress.dart';
import 'package:flutter/material.dart';

class StorageInformationWidget extends StatelessWidget {
  final int totalBytes;
  final int freeBytes;

  const StorageInformationWidget({
    super.key,
    required this.totalBytes,
    required this.freeBytes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Card(
        color: Color(0xFF1A1D1C),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BubbleProgress(
                  percentage: (freeBytes) * 100 / totalBytes,
                  totalBubbles: 48,
                  size: 9,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    freeBytes.toReadableBytes(),
                    style: TextStyle(fontSize: 22),
                  ),
                  Text("left"),
                ],
              ),
              Text(
                "Storage",
                style: TextStyle(color: Color(0xFF6C696E), fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
