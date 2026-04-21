import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/battery_stat_card.dart';
import 'package:android_tools/features/information/presentation/widgets/device_stat_card.dart';
import 'package:android_tools/features/screenshot/presentation/widgets/screenshot_button.dart';
import 'package:flutter/material.dart';



/// Header de l'écran device info : DeviceStatCard pleine largeur avec le bouton
/// screenshot intégré, puis les cartes secondaires (batterie, …) en dessous.
///
/// Note : ne pas envelopper ce widget dans MoveWindow — il vit à l'intérieur
/// d'un ListView qui lui donne une hauteur non bornée, incompatible avec
/// la Column interne de MoveWindow (mainAxisSize: max).
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
            actions: [
              ScreenshotButton(device: state.device),
            ],
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
