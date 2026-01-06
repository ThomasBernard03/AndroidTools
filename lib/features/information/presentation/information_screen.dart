import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/android_version_card.dart';
import 'package:android_tools/features/information/presentation/widgets/apk_installer_drop_target.dart';
import 'package:android_tools/features/information/presentation/widgets/information_recap_item.dart';
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
                      Row(
                        spacing: 16,
                        children: [
                          Image.asset("assets/pixel_10.png", width: 200),
                          Column(
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
                                value: state.deviceInformation?.model ?? "-",
                              ),
                            ],
                          ),
                        ],
                      ),
                      Wrap(
                        children: [
                          BlocBuilder<InformationBloc, InformationState>(
                            builder: (context, state) {
                              return AndroidVersionCard(
                                androidVersion:
                                    state.deviceInformation?.version ?? "",
                              );
                            },
                          ),
                          ApkInstallerDropTarget(
                            onInstallApk: (path) {
                              context.read<InformationBloc>().add(
                                OnInstallApplication(applicationFilePath: path),
                              );
                            },
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
}
