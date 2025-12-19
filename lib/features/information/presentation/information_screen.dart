import 'dart:ui';

import 'package:android_tools/features/information/presentation/information_bloc.dart';
import 'package:android_tools/features/information/presentation/widgets/android_version_card.dart';
import 'package:android_tools/shared/core/string_extensions.dart';
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
        body: Wrap(
          children: [
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
                return AndroidVersionCard(
                  androidVersion: state.deviceInformation?.version ?? "",
                );
              },
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
                        Text("SN :${state.deviceInformation?.serialNumber}"),
                        Text("Model :${state.deviceInformation?.model}"),
                        Text("Version :${state.deviceInformation?.version}"),
                      ],
                    ),
                  ),
                );
              },
            ),
            AndroidVersionCard(androidVersion: "17"),
            AndroidVersionCard(androidVersion: "16"),
            AndroidVersionCard(androidVersion: "15"),
            AndroidVersionCard(androidVersion: "14"),
            AndroidVersionCard(androidVersion: "13"),
            AndroidVersionCard(androidVersion: "12"),
            AndroidVersionCard(androidVersion: "11"),
            AndroidVersionCard(androidVersion: "10"),
            AndroidVersionCard(androidVersion: "9"),
            AndroidVersionCard(androidVersion: "8"),
            AndroidVersionCard(androidVersion: "7"),
            AndroidVersionCard(androidVersion: "6"),
            AndroidVersionCard(androidVersion: "5"),
            AndroidVersionCard(androidVersion: "4"),
            AndroidVersionCard(androidVersion: "3"),
            AndroidVersionCard(androidVersion: "2"),
            AndroidVersionCard(androidVersion: "1"),
          ],
        ),
      ),
    );
  }
}
