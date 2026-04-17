import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/android_version_card.dart';
import 'package:android_tools/features/information/presentation/widgets/dynamic_device_preview.dart';
import 'package:android_tools/features/information/presentation/widgets/information_recap_item.dart';
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
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: BlocBuilder<InformationBloc, InformationState>(
                builder: (context, state) {
                  return Text(
                    state.device?.name ?? "",
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
                      icon: Icon(Icons.refresh),
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

            return ListView(
              children: [
                SizedBox.fromSize(size: Size.fromHeight(50)),
                Center(
                  child: Row(
                    spacing: 32,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDevicePreview(state),
                      SizedBox(
                        height: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            InformationRecapItem(
                              label: "Manufacturer",
                              value:
                                  state.deviceInformation?.manufacturer ?? "-",
                            ),
                            InformationRecapItem(
                              label: "Serial Number",
                              value:
                                  state.deviceInformation?.serialNumber ?? "-",
                            ),
                            InformationRecapItem(
                              label: "Model",
                              value: state.deviceInformation?.model ?? "-",
                            ),
                            InformationRecapItem(
                              label: "Android Version",
                              value: state.deviceInformation?.version ?? "-",
                            ),
                            const Spacer(),
                            if (state.deviceBatteryInformation != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${state.deviceBatteryInformation?.level}%",
                                  ),
                                  SizedBox(
                                    width: 60,
                                    height: 4,
                                    child: LinearProgressIndicator(
                                      value:
                                          state
                                                  .deviceBatteryInformation
                                                  ?.isPlugged ==
                                              true
                                          ? null
                                          : ((state
                                                            .deviceBatteryInformation
                                                            ?.level ??
                                                        0) /
                                                    100)
                                                .toDouble(),
                                      color: Colors.white,
                                      backgroundColor: Color(0xFF2B2F33),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
