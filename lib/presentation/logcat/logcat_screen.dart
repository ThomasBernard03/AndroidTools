import 'package:android_tools/domain/entities/device_entity.dart';
import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/presentation/logcat/core/logcat_level_extensions.dart';
import 'package:android_tools/presentation/logcat/logcat_bloc.dart';
import 'package:android_tools/presentation/logcat/widgets/logcat_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatScreen extends StatefulWidget {
  const LogcatScreen({super.key});

  @override
  State<LogcatScreen> createState() => _LogcatScreenState();
}

class _LogcatScreenState extends State<LogcatScreen> {
  final bloc = LogcatBloc();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bloc.add(OnStartListeningLogcat());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  final availableLogcatSizes = [500, 1000, 2000, 5000, 10000];
  final availableLogcatLevels = [
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            spacing: 16,
            children: [
              BlocBuilder<LogcatBloc, LogcatState>(
                builder: (context, state) {
                  return DropdownButton<DeviceEntity>(
                    value: state.selectedDevice,
                    elevation: 16,
                    onChanged: (DeviceEntity? value) {
                      if (value == null) return;
                      context.read<LogcatBloc>().add(
                        OnSelectedDeviceChanged(device: value),
                      );
                    },
                    items: state.devices.map<DropdownMenuItem<DeviceEntity>>((
                      DeviceEntity value,
                    ) {
                      return DropdownMenuItem<DeviceEntity>(
                        value: value,
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.mobile_friendly, size: 16),
                            Text(value.name),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          actions: [
            Row(
              spacing: 8,
              children: [
                BlocBuilder<LogcatBloc, LogcatState>(
                  builder: (context, state) {
                    return DropdownButton<int>(
                      value: state.maxLogcatLines,
                      elevation: 16,
                      onChanged: (int? value) {
                        context.read<LogcatBloc>().add(
                          OnLogcatMaxLinesChanged(
                            maxLines: value ?? availableLogcatSizes.first,
                          ),
                        );
                      },
                      items: availableLogcatSizes.map<DropdownMenuItem<int>>((
                        int value,
                      ) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    );
                  },
                ),
                BlocBuilder<LogcatBloc, LogcatState>(
                  builder: (context, state) {
                    return DropdownButton<LogcatLevel>(
                      value: state.minimumLogLevel,
                      elevation: 16,
                      onChanged: (LogcatLevel? value) {
                        if (state.minimumLogLevel == value) return;
                        context.read<LogcatBloc>().add(
                          OnMinimumLogLevelChanged(minimumLogLevel: value),
                        );
                      },
                      items: availableLogcatLevels
                          .map<DropdownMenuItem<LogcatLevel>>((
                            LogcatLevel value,
                          ) {
                            return DropdownMenuItem<LogcatLevel>(
                              value: value,
                              child: Row(
                                spacing: 8,
                                children: [
                                  Icon(value.icon(), color: value.textColor()),
                                  Text(value.name.toString()),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                ),
              ],
            ),
            VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Clear logs",
              onPressed: () {
                bloc.add(OnClearLogcat());
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh",
              onPressed: () {
                bloc.add(OnRefreshLogcat());
              },
            ),
            BlocBuilder<LogcatBloc, LogcatState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
                  tooltip: "Play / Pause",
                  onPressed: () {
                    final event = state.isPaused
                        ? OnResumeLogcat()
                        : OnPauseLogcat();
                    context.read<LogcatBloc>().add(event);
                  },
                );
              },
            ),
            BlocBuilder<LogcatBloc, LogcatState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(state.isSticky ? Icons.lock : Icons.lock_open),
                  tooltip: "Toggle Sticky",
                  onPressed: () {
                    context.read<LogcatBloc>().add(
                      OnToggleIsSticky(isSticky: !state.isSticky),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: BlocListener<LogcatBloc, LogcatState>(
          listener: (context, state) {
            if (state.isSticky) {
              _scrollToBottom();
            }
          },
          child: BlocBuilder<LogcatBloc, LogcatState>(
            builder: (context, state) {
              return ListView.builder(
                reverse: true,
                padding: EdgeInsets.all(8),
                controller: _scrollController,
                itemCount: state.logs.take(state.maxLogcatLines).length,
                itemBuilder: (context, index) {
                  return LogcatLine(
                    line: state.logs.reversed
                        .take(state.maxLogcatLines)
                        .toList()[index],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
