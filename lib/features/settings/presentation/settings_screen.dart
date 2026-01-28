import 'package:android_tools/features/settings/presentation/settings_bloc.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
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
    bloc.add(OnLoadMaxHistorySize());
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
            title: Text("Settings"),
          ),
        ),
      ),
      body: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.all(8),
              children: [
                Column(
                  spacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Updates"),
                        Card(
                          clipBehavior: Clip.hardEdge,
                          color: Color(0xFF212121),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.code),
                                title: Text("Open on github"),
                                subtitle: Text(
                                  "Open Browser on Github open source project",
                                ),
                                onTap: () => context.read<SettingsBloc>().add(
                                  OnOpenGithubProject(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 0,
                                ),
                                child: Divider(
                                  color: Color.fromARGB(255, 76, 76, 76),
                                  height: 1,
                                ),
                              ),

                              ListTile(
                                leading: Icon(Icons.update),
                                title: Text("Check for updates"),
                                onTap: () => context.read<SettingsBloc>().add(
                                  OnCheckForUpdates(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Support"),

                        Card(
                          clipBehavior: Clip.hardEdge,
                          color: Color(0xFF212121),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.bug_report),
                                title: Text("Create an issue"),
                                subtitle: Text("Create new issue on Github"),
                                onTap: () => context.read<SettingsBloc>().add(
                                  OnCreateIssue(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 0,
                                ),
                                child: Divider(
                                  color: Color.fromARGB(255, 76, 76, 76),
                                  height: 1,
                                ),
                              ),
                              ListTile(
                                leading: Icon(Icons.browse_gallery),
                                title: Text("Open log directory"),
                                subtitle: Text(
                                  "Open application log directory to handle problems",
                                ),
                                onTap: () => context.read<SettingsBloc>().add(
                                  OnOpenLogDirectory(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Installed application history"),

                        Card(
                          clipBehavior: Clip.hardEdge,
                          color: Color(0xFF212121),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Max history size",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          "${state.maxHistorySize}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Slider(
                                      value: state.maxHistorySize.toDouble(),
                                      min: 0,
                                      max: 10,
                                      divisions: 10,
                                      label: state.maxHistorySize.toString(),
                                      onChanged: (value) {
                                        context.read<SettingsBloc>().add(
                                          OnMaxHistorySizeChanged(
                                            value.toInt(),
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      "Maximum number of installed applications to keep in history (0-10)",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 0,
                                ),
                                child: Divider(
                                  color: Color.fromARGB(255, 76, 76, 76),
                                  height: 1,
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  "Clear installed applications history",
                                ),
                                subtitle: Text(
                                  "Remove all installed applications history and cached APK files",
                                ),
                                onTap: () => context.read<SettingsBloc>().add(
                                  OnClearInstalledApplicationHistory(),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
