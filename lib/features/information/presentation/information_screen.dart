import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/device_preview.dart';
import 'package:android_tools/features/information/presentation/widgets/information_recap_item.dart';
import 'package:android_tools/features/information/presentation/widgets/storage_information_widget.dart';
import 'package:android_tools/shared/presentation/refresh_device_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: MoveWindow(
            child: AppBar(
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
                            version: state.deviceInformation?.version ?? "",
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

                Padding(
                  padding: EdgeInsetsGeometry.all(42),
                  child: Column(
                    children: [
                      BlocBuilder<InformationBloc, InformationState>(
                        builder: (context, state) {
                          return StorageInformationWidget(
                            totalBytes:
                                state.deviceStorageInformation?.totalBytes ?? 1,
                            freeBytes:
                                state
                                    .deviceStorageInformation
                                    ?.availableBytes ??
                                0,
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
