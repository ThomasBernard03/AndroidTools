import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/presentation/core/logcat_level_extensions.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatAppbar extends StatefulWidget {
  const LogcatAppbar({super.key});

  @override
  State<LogcatAppbar> createState() => _LogcatAppbarState();
}

class _LogcatAppbarState extends State<LogcatAppbar> {
  final availableLogcatSizes = [500, 1000, 2000, 5000, 10000];
  final availableLogcatLevels = [
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
              );
            },
          ),
          Row(
            children: [
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
                  const VerticalDivider(),

                  BlocBuilder<LogcatBloc, LogcatState>(
                    builder: (context, state) {
                      return IconButton(
                        icon: Icon(
                          state.isSticky ? Icons.lock : Icons.lock_open,
                        ),
                        tooltip: "Toggle Sticky",
                        onPressed: () {
                          context.read<LogcatBloc>().add(
                            OnToggleIsSticky(isSticky: !state.isSticky),
                          );
                        },
                      );
                    },
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        BlocBuilder<LogcatBloc, LogcatState>(
                          builder: (context, state) {
                            return FilledButton(
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  BeveledRectangleBorder(),
                                ),
                              ),
                              child: Icon(
                                state.isPaused ? Icons.play_arrow : Icons.pause,
                              ),
                              onPressed: () {
                                final event = state.isPaused
                                    ? OnResumeLogcat()
                                    : OnPauseLogcat();
                                context.read<LogcatBloc>().add(event);
                              },
                            );
                          },
                        ),
                        FilledButton(
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              BeveledRectangleBorder(),
                            ),
                          ),
                          onPressed: () {
                            context.read<LogcatBloc>().add(OnRefreshLogcat());
                          },
                          child: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  LogcatButton(
                    color: Color.fromARGB(255, 213, 36, 54),
                    icon: Icons.delete_outline_rounded,
                    onPressed: () =>
                        context.read<LogcatBloc>().add(OnClearLogcat()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
