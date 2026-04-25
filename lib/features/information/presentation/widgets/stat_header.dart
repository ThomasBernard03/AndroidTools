import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/battery_stat_card.dart';
import 'package:android_tools/features/information/presentation/widgets/device_stat_card.dart';
import 'package:android_tools/features/screenshot/presentation/widgets/screenshot_button.dart';
import 'package:flutter/material.dart';

/// Header of the device info screen: Full-width DeviceStatCard with integrated
/// screenshot button, followed by secondary cards (battery, etc.) below.
///
/// Note: Do not wrap this widget in MoveWindow — it lives inside a ListView
/// that provides unbounded height, incompatible with MoveWindow's internal
/// Column (mainAxisSize: max).
class StatHeader extends StatelessWidget {
  final InformationState state;

  const StatHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final info = state.deviceInformation;
    final battery = state.deviceBatteryInformation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(
          width: double.infinity,
          child: DeviceStatCard(
            deviceName: info?.model ?? state.device?.name ?? 'Unknown',
            manufacturer: info?.manufacturer ?? '',
            serial: info?.serialNumber ?? '',
            androidVersion: info?.version ?? '',
            actions: [ScreenshotButton(device: state.device)],
          ),
        ),
        if (battery != null)
          Row(
            spacing: 12,
            children: [
              SizedBox(width: 200, child: BatteryStatCard(battery: battery)),
            ],
          ),
      ],
    );
  }
}
