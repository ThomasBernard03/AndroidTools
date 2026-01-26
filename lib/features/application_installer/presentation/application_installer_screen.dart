import 'package:android_tools/features/application_installer/presentation/application_installer_bloc.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
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
  bool isDropping = false;

  @override
  void initState() {
    super.initState();
    bloc.add(OnAppearing());
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
        child: Stack(
          children: [
            BlocBuilder<ApplicationInstallerBloc, ApplicationInstallerState>(
              builder: (context, state) {
                return DropTarget(
                  onDragEntered: (_) {
                    setState(() => isDropping = true);
                  },
                  onDragExited: (_) {
                    setState(() => isDropping = false);
                  },
                  onDragDone: (details) {
                    final dropItem = details.files.firstOrNull;
                    final path = dropItem?.path;
                    if (path == null) {
                      return;
                    }

                    context.read<ApplicationInstallerBloc>().add(
                      OnInstallApk(apkPath: path),
                    );
                  },
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            spacing: 8,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Install Apk file to connected device",
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                "You can drag and drop one or more APK files into this screen to install them on the selected device. The installed APKs will be saved locally in a temporary folder so you can find them and reinstall them more easily. You can change this setting in the settings.",
                              ),
                              TextButton(
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['apk'],
                                      );
                                  if ((result?.files.isEmpty ?? false)) {
                                    return;
                                  }
                                  final path = result!.files.first.path!;

                                  if (context.mounted) {
                                    context
                                        .read<ApplicationInstallerBloc>()
                                        .add(OnInstallApk(apkPath: path));
                                  }
                                },
                                child: Text("Open file explorer"),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Divider(),

                      Text("History"),
                    ],
                  ),
                );
              },
            ),

            if (isDropping)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withAlpha(60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.file_download_outlined,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Drop your .apk files here',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child:
                  BlocBuilder<
                    ApplicationInstallerBloc,
                    ApplicationInstallerState
                  >(
                    builder: (context, state) {
                      return state.isLoading
                          ? LinearProgressIndicator()
                          : SizedBox.shrink();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
