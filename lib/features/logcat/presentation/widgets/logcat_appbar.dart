import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/presentation/core/logcat_level_extensions.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatAppbar extends StatelessWidget {
  final availableLogcatSizes = [500, 1000, 2000, 5000, 10000];
  final availableLogcatLevels = [
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
  ];

  LogcatAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BlocBuilder<LogcatBloc, LogcatState>(
          builder: (context, state) {
            return state.devices.isNotEmpty
                ? DropdownButton<DeviceEntity>(
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
                  )
                : SizedBox.shrink();
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                BlocBuilder<LogcatBloc, LogcatState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: 300,
                      child: Autocomplete<ProcessEntity>(
                        displayStringForOption: (item) =>
                            "${item.packageName} (${item.processId})",
                        onSelected: (option) {
                          context.read<LogcatBloc>().add(
                            OnProcessSelected(process: option),
                          );
                        },
                        optionsBuilder: (textEditingValue) {
                          return state.processes.where(
                            (p) =>
                                p.packageName.contains(textEditingValue.text),
                          );
                        },
                      ),
                    );
                  },
                ),
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
                VerticalDivider(),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Clear logs",
                  onPressed: () {
                    context.read<LogcatBloc>().add(OnClearLogcat());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh",
                  onPressed: () {
                    context.read<LogcatBloc>().add(OnRefreshLogcat());
                  },
                ),
                BlocBuilder<LogcatBloc, LogcatState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        state.isPaused ? Icons.play_arrow : Icons.pause,
                      ),
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
          ],
        ),
      ],
    );
  }
}
