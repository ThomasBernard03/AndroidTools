import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/info_card.dart';
import 'package:android_tools/features/information/presentation/widgets/info_cards_grid.dart';
import 'package:android_tools/features/information/presentation/widgets/stat_header.dart';
import 'package:android_tools/shared/presentation/refresh_device_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InformationScreen extends StatelessWidget {
  final bloc = InformationBloc();

  InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc..add(OnAppearing()),
      child: BlocBuilder<InformationBloc, InformationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.device == null) {
            return Scaffold(
              body: Center(
                child: RefreshDeviceButton(
                  onPressed: () =>
                      context.read<InformationBloc>().add(OnRefreshDevices()),
                ),
              ),
            );
          }

          final info = state.deviceInformation;
          final raw = info?.rawInformation ?? {};

          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    children: [
                      StatHeader(state: state),
                      const SizedBox(height: 24),
                      InfoCardsGrid(
                        cards: [
                          InfoCard(
                            title: 'System',
                            rows: [
                              ('Manufacturer', info?.manufacturer ?? '—'),
                              ('Model', info?.model ?? '—'),
                              ('Serial', info?.serialNumber ?? '—'),
                              ('Android', info?.version ?? '—'),
                              ('Build ID', raw['ro.build.id'] ?? '—'),
                              ('ABI', raw['ro.product.cpu.abi'] ?? '—'),
                              if (raw['ro.soc.model'] != null)
                                ('SoC', raw['ro.soc.model']!),
                              (
                                'Security patch',
                                raw['ro.build.version.security_patch'] ?? '—',
                              ),
                              if (info?.screenWidth != null &&
                                  info?.screenHeight != null)
                                (
                                  'Screen',
                                  '${info!.screenWidth} × ${info.screenHeight}',
                                ),
                            ],
                          ),
                          if (state.deviceBatteryInformation != null)
                            InfoCard(
                              title: 'Battery',
                              rows: [
                                (
                                  'Level',
                                  '${state.deviceBatteryInformation!.level}%',
                                ),
                                (
                                  'Status',
                                  state.deviceBatteryInformation!.isPlugged
                                      ? 'Charging'
                                      : 'Discharging',
                                ),
                                (
                                  'Temperature',
                                  '${state.deviceBatteryInformation!.temperature.toStringAsFixed(1)} °C',
                                ),
                                (
                                  'Voltage',
                                  '${state.deviceBatteryInformation!.voltage} mV',
                                ),
                                (
                                  'Health',
                                  state.deviceBatteryInformation!.health.name,
                                ),
                                if (state
                                        .deviceBatteryInformation!
                                        .technology !=
                                    null)
                                  (
                                    'Technology',
                                    state.deviceBatteryInformation!.technology!,
                                  ),
                              ],
                            ),
                          InfoCard(
                            title: 'Build',
                            rows: [
                              ('Brand', raw['ro.product.brand'] ?? '—'),
                              ('Device', raw['ro.product.device'] ?? '—'),
                              (
                                'Fingerprint',
                                _truncate(
                                  raw['ro.build.fingerprint'] ?? '—',
                                  32,
                                ),
                              ),
                              (
                                'Incremental',
                                raw['ro.build.version.incremental'] ?? '—',
                              ),
                              ('SDK', raw['ro.build.version.sdk'] ?? '—'),
                              ('Build type', raw['ro.build.type'] ?? '—'),
                              ('Tags', raw['ro.build.tags'] ?? '—'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ), // Expanded
              ],
            ), // Column
          );
        },
      ),
    );
  }

  String _truncate(String s, int maxLen) =>
      s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
}
