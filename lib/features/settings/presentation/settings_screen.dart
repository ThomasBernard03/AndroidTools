import 'package:android_tools/features/settings/presentation/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bloc = SettingsBloc();

  @override
  void initState() {
    super.initState();
  }

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
                ListTile(
                  leading: Icon(Icons.code),
                  title: Text("Open on github"),
                  subtitle: Text("Open Browser on Github open source project"),
                  onTap: () =>
                      context.read<SettingsBloc>().add(OnOpenGithubProject()),
                ),
                ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text("Open log directory"),
                  subtitle: Text(
                    "Open application log directory to handle problems",
                  ),
                  onTap: () =>
                      context.read<SettingsBloc>().add(OnOpenLogDirectory()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
