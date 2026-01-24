import 'package:android_tools/features/application_installer/presentation/application_installer_bloc.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApplicationInstallerScreen extends StatefulWidget {
  const ApplicationInstallerScreen({super.key});

  @override
  State<ApplicationInstallerScreen> createState() =>
      _ApplicationInstallerScreenState();
}

class _ApplicationInstallerScreenState
    extends State<ApplicationInstallerScreen> {
  final bloc = ApplicationInstallerBloc();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF151515),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: MoveWindow(
          child: AppBar(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text("Application installer"),
          ),
        ),
      ),
      body: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<ApplicationInstallerBloc, ApplicationInstallerState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(spacing: 16, children: [
           
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
