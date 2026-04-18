import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/android_version_card.dart';
import 'package:android_tools/features/information/presentation/widgets/dynamic_device_preview.dart';
import 'package:android_tools/features/screenshot/presentation/widgets/screenshot_button.dart';
import 'package:android_tools/shared/presentation/refresh_device_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InformationScreen extends StatelessWidget {
  final bloc = InformationBloc();

  InformationScreen({super.key});

  static const _versionColors = {
    "1": Color(0xFFA5C736),
    "2": Color(0xFF3E7B2E),
    "3": Color(0xFF00467B),
    "4": Color(0xFFED161E),
    "5": Color(0xFF9C28B1),
    "6": Color(0xFFE91E63),
    "7": Color(0xFF083042),
    "8": Color(0xFFDABC63),
    "9": Color(0xFF083042),
    "10": Color(0xFFFEFEFE),
    "11": Color(0xFFF86734),
    "12": Color(0xFFFFFFFF),
    "13": Color(0xFF073042),
    "14": Color(0xFF073042),
    "15": Color(0xFF202124),
    "16": Color(0xFF202124),
  };

  Widget _buildDevicePreview(InformationState state) {
    final w = state.deviceInformation?.screenWidth;
    final h = state.deviceInformation?.screenHeight;

    if (w != null && h != null) {
      final version = state.deviceInformation?.version ?? "";
      final majorVersion = version.split('.').first;
      final screenColor =
          _versionColors[majorVersion] ?? const Color(0xFF0A0A0A);
      return DynamicDevicePreview(
        screenWidth: w,
        screenHeight: h,
        screenColor: screenColor,
        child: SizedBox(
          width: 100,
          height: 100,
          child: AndroidVersionCard(
            androidVersion: version,
          ).androidVersionLogo(version),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(25),
            blurRadius: 64,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset("assets/pixels/pixel_android.png", height: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc..add(OnAppearing()),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: MoveWindow(
            child: AppBar(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: BlocBuilder<InformationBloc, InformationState>(
                builder: (context, state) {
                  return Text(
                    state.device?.name ?? "Device",
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                },
              ),
              actions: [
                BlocBuilder<InformationBloc, InformationState>(
                  builder: (context, state) {
                    return ScreenshotButton(device: state.device);
                  },
                ),
                BlocBuilder<InformationBloc, InformationState>(
                  builder: (context, state) {
                    return IconButton(
                      onPressed: () {
                        context.read<InformationBloc>().add(OnRefreshDevices());
                      },
                      icon: const Icon(Icons.refresh),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<InformationBloc, InformationState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }

            if (state.device == null) {
              return Center(
                child: RefreshDeviceButton(
                  onPressed: () =>
                      context.read<InformationBloc>().add(OnRefreshDevices()),
                ),
              );
            }

            final info = state.deviceInformation;
            final raw = info?.rawInformation ?? {};

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Device preview + quick stats row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    _buildDevicePreview(state),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            info?.model ?? state.device?.name ?? "",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            info?.manufacturer ?? "",
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (state.deviceBatteryInformation != null)
                            _BatteryIndicator(
                              battery: state.deviceBatteryInformation!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cards grid
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _InfoCard(
                      title: "System",
                      rows: [
                        ("Manufacturer", info?.manufacturer ?? "—"),
                        ("Model", info?.model ?? "—"),
                        ("Serial", info?.serialNumber ?? "—"),
                        ("Android", info?.version ?? "—"),
                        ("Build ID", raw['ro.build.id'] ?? "—"),
                        ("ABI", raw['ro.product.cpu.abi'] ?? "—"),
                        if (raw['ro.soc.model'] != null)
                          ("SoC", raw['ro.soc.model']!),
                        (
                          "Security patch",
                          raw['ro.build.version.security_patch'] ?? "—"
                        ),
                        if (info?.screenWidth != null &&
                            info?.screenHeight != null)
                          (
                            "Screen",
                            "${info!.screenWidth} × ${info.screenHeight}"
                          ),
                      ],
                    ),
                    if (state.deviceBatteryInformation != null)
                      _InfoCard(
                        title: "Battery",
                        rows: [
                          (
                            "Level",
                            "${state.deviceBatteryInformation!.level}%"
                          ),
                          (
                            "Status",
                            state.deviceBatteryInformation!.isPlugged
                                ? "Charging"
                                : "Discharging"
                          ),
                          (
                            "Temperature",
                            "${state.deviceBatteryInformation!.temperature.toStringAsFixed(1)} °C"
                          ),
                          (
                            "Voltage",
                            "${state.deviceBatteryInformation!.voltage} mV"
                          ),
                          (
                            "Health",
                            state.deviceBatteryInformation!.health.name
                          ),
                          if (state.deviceBatteryInformation!.technology !=
                              null)
                            (
                              "Technology",
                              state.deviceBatteryInformation!.technology!
                            ),
                        ],
                      ),
                    _InfoCard(
                      title: "Build",
                      rows: [
                        ("Brand", raw['ro.product.brand'] ?? "—"),
                        ("Device", raw['ro.product.device'] ?? "—"),
                        (
                          "Fingerprint",
                          _truncate(raw['ro.build.fingerprint'] ?? "—", 32)
                        ),
                        ("Incremental", raw['ro.build.version.incremental'] ?? "—"),
                        ("SDK", raw['ro.build.version.sdk'] ?? "—"),
                        ("Build type", raw['ro.build.type'] ?? "—"),
                        ("Tags", raw['ro.build.tags'] ?? "—"),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _truncate(String s, int maxLen) =>
      s.length > maxLen ? '${s.substring(0, maxLen)}…' : s;
}

class _BatteryIndicator extends StatelessWidget {
  final BatteryInfo battery;
  const _BatteryIndicator({required this.battery});

  @override
  Widget build(BuildContext context) {
    final level = battery.level / 100.0;
    final color = level < 0.2
        ? Colors.red
        : level < 0.5
        ? Colors.orange
        : const Color(0xFF4CAF50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Row(
          spacing: 6,
          children: [
            Icon(
              battery.isPlugged
                  ? Icons.battery_charging_full
                  : Icons.battery_std,
              size: 14,
              color: color,
            ),
            Text(
              "${battery.level}%",
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(
          width: 120,
          height: 4,
          child: LinearProgressIndicator(
            value: battery.isPlugged ? null : level,
            color: color,
            backgroundColor: const Color(0xFF2B2F33),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final dimColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dimColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: dimColor,
              ),
            ),
          ),
          Divider(
            height: 1,
            color: dimColor.withValues(alpha: 0.15),
          ),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      style: TextStyle(fontSize: 12, color: dimColor),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "monospace",
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
