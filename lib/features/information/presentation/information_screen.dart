import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/apk_installer_drop_target.dart';
import 'package:android_tools/features/information/presentation/widgets/device_preview.dart';
import 'package:android_tools/features/information/presentation/widgets/information_recap_item.dart';
import 'package:android_tools/features/information/presentation/widgets/storage_information_widget.dart';
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
      child: Scaffold(
        body: BlocBuilder<InformationBloc, InformationState>(
          builder: (context, state) {
            return state.deviceInformation == null
                ? Center(
                    child: RefreshDeviceButton(
                      onPressed: () => context.read<InformationBloc>().add(
                        OnRefreshDevices(),
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  state.device?.name ?? "",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          spacing: 32,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
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
                                child: DevicePreview(
                                  version:
                                      state.deviceInformation?.version ?? "",
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 400,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 8,
                                children: [
                                  InformationRecapItem(
                                    label: "Manufacturer",
                                    value:
                                        state.deviceInformation?.manufacturer ??
                                        "-",
                                  ),

                                  InformationRecapItem(
                                    label: "Serial Number",
                                    value:
                                        state.deviceInformation?.serialNumber ??
                                        "-",
                                  ),
                                  InformationRecapItem(
                                    label: "Model",
                                    value:
                                        state.deviceInformation?.model ?? "-",
                                  ),
                                  InformationRecapItem(
                                    label: "Android Version",
                                    value:
                                        state.deviceInformation?.version ?? "-",
                                  ),

                                  const Spacer(),

                                  if (state.deviceBatteryInformation != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                                        ?.isCharging ==
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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

                      Padding(
                        padding: EdgeInsetsGeometry.all(42),
                        child: Column(
                          children: [
                            BlocBuilder<InformationBloc, InformationState>(
                              builder: (context, state) {
                                return StorageInformationWidget(
                                  totalBytes:
                                      state
                                          .deviceStorageInformation
                                          ?.totalBytes ??
                                      1,
                                  freeBytes:
                                      state
                                          .deviceStorageInformation
                                          ?.freeBytes ??
                                      0,
                                );
                              },
                            ),
                            ApkInstallerDropTarget(
                              onInstallApk: (path) {
                                context.read<InformationBloc>().add(
                                  OnInstallApplication(
                                    applicationFilePath: path,
                                  ),
                                );
                              },
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
