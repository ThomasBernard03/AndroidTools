import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/presentation/widgets/stat_card_shell.dart';
import 'package:flutter/material.dart';

class BatteryStatCard extends StatelessWidget {
  final BatteryInfo battery;

  const BatteryStatCard({super.key, required this.battery});

  @override
  Widget build(BuildContext context) {
    final level = battery.level / 100.0;
    final dim = Theme.of(context).colorScheme.surfaceContainerHighest;
    final color = level < 0.2
        ? Colors.red
        : level < 0.5
        ? Colors.orange
        : const Color(0xFF4CAF50);

    final statusText = battery.isPlugged ? 'Charging' : 'Discharging';
    final tempText = '${battery.temperature.toStringAsFixed(1)} °C';

    return StatCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(
                battery.isPlugged
                    ? Icons.battery_charging_full_rounded
                    : Icons.battery_std_rounded,
                size: 16,
                color: dim,
              ),
              Text(
                'Battery',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: dim,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 6,
            children: [
              Text(
                '${battery.level}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: battery.isPlugged ? null : level,
                    minHeight: 4,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$statusText · $tempText',
            style: TextStyle(fontSize: 11, color: dim),
          ),
        ],
      ),
    );
  }
}
