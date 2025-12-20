import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/android_version_card.dart';
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
                          Card.filled(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(Icons.add_rounded, size: 200),
                                  Text(
                                    "Drag and drop your .apk file here to install app on connected device",
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          BlocBuilder<InformationBloc, InformationState>(
                            builder: (context, state) {
                              return Card.filled(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Manufacturer :${state.deviceInformation?.manufacturer}",
                                      ),
                                      Text(
                                        "SN :${state.deviceInformation?.serialNumber}",
                                      ),
                                      Text(
                                        "Model :${state.deviceInformation?.model}",
                                      ),
                                      Text(
                                        "Version :${state.deviceInformation?.version}",
                                      ),
                                    ],
                                  ),
                                ),
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
