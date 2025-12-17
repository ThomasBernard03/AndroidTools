import 'package:android_tools/features/settings/presentation/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  final bloc = SettingsBloc();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return Column(
              children: [
                TextButton(
                  onPressed: () {
                    context.read<SettingsBloc>().add(OnOpenLogDirectory());
                  },
                  child: Text("Open log folder"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
