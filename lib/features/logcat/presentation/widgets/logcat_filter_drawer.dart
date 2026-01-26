import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/presentation/core/logcat_level_extensions.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatFilterDrawer extends StatelessWidget {
  final availableLogcatLevels = [
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
  ];

  LogcatFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: ContinuousRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Minimum level"),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<LogcatBloc, LogcatState>(
                    builder: (context, state) {
                      return DropdownButtonFormField<LogcatLevel>(
                        initialValue: state.minimumLogLevel,
                        padding: EdgeInsets.symmetric(horizontal: 15),
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
                                    Icon(
                                      value.icon(),
                                      color: value.textColor(),
                                    ),
                                    Text(value.name.toString()),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
            Text("Package"),
            BlocBuilder<LogcatBloc, LogcatState>(
              builder: (context, state) {
                return Autocomplete<ProcessEntity>(
                  initialValue: TextEditingValue(
                    text: state.selectedProcess?.packageName ?? "",
                  ),
                  displayStringForOption: (item) =>
                      "${item.packageName} (${item.processId})",

                  onSelected: (option) {
                    context.read<LogcatBloc>().add(
                      OnProcessSelected(process: option),
                    );
                  },

                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return BlocListener<LogcatBloc, LogcatState>(
                          listenWhen: (previous, current) =>
                              previous.selectedProcess !=
                              current.selectedProcess,
                          listener: (context, state) {
                            if (state.selectedProcess == null) {
                              controller.clear();
                            }
                          },
                          child: TextFormField(
                            controller: controller,
                            onChanged: (value) {
                              if (state.selectedProcess != null) {
                                context.read<LogcatBloc>().add(
                                  OnProcessSelected(process: null),
                                );
                                controller.clear();
                              }
                            },
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: "Rechercher un process...",
                            ),
                          ),
                        );
                      },

                  optionsBuilder: (textEditingValue) {
                    return state.processes.where(
                      (p) => p.packageName.contains(textEditingValue.text),
                    );
                  },
                );
              },
            ),
            BlocBuilder<LogcatBloc, LogcatState>(
              builder: (context, state) {
                return Row(
                  children: [
                    Checkbox(
                      value: state.isShowProcessThreadIds,
                      onChanged: (value) {
                        context.read<LogcatBloc>().add(
                          OnIsShowProcessThreadIdsChanged(
                            isShowProcessThreadIds: value!,
                          ),
                        );
                      },
                    ),
                    Text("Show Process/Thread Id"),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
