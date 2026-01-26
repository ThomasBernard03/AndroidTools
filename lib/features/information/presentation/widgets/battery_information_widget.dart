import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/presentation/widgets/bubble_progress.dart';
import 'package:flutter/material.dart';

class BatteryInformationWidget extends StatelessWidget {
  final int level;
  final bool isPlugged;
  final BatteryHealth? health;
  final double? temperature;

  const BatteryInformationWidget({
    super.key,
    required this.level,
    required this.isPlugged,
    this.health,
    this.temperature,
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
                  percentage: level.toDouble(),
                  totalBubbles: 48,
                  size: 9,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    "$level%",
                    style: TextStyle(fontSize: 22),
                  ),
                  if (isPlugged)
                    Icon(
                      Icons.bolt,
                      size: 18,
                      color: Colors.amber,
                    ),
                ],
              ),
              Text(
                "Battery",
                style: TextStyle(color: Color(0xFF6C696E), fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
