import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/presentation/logcat/core/logcat_colors.dart';
import 'package:android_tools/presentation/logcat/logcat_bloc.dart';
import 'package:android_tools/presentation/logcat/widgets/logcat_level_filter_popup_menu_item.dart';
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
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Logcat"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Clear logs",
              onPressed: () {
                bloc.add(OnClearLogcat());
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
            BlocBuilder<LogcatBloc, LogcatState>(
              builder: (context, state) {
                return PopupMenuButton<LogcatLevel?>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: "Filter by level",
                  initialValue: LogcatLevel.debug,
                  onSelected: (selected) {
                    context.read<LogcatBloc>().add(
                      OnMinimumLogLevelChanged(minimumLogLevel: selected),
                    );
                  },
                  itemBuilder: (context) {
                    return [
                      LogcatLevelFilterPopupMenuItem<LogcatLevel?>(
                        value: null,
                        icon: Icons.filter_none,
                        color: Colors.black,
                        text: "All",
                      ),
                      LogcatLevelFilterPopupMenuItem(
                        value: LogcatLevel.debug,
                        icon: Icons.bug_report,
                        color: LogcatColors.debugTextColor,
                        text: "Debug",
                      ),
                      LogcatLevelFilterPopupMenuItem(
                        value: LogcatLevel.info,
                        icon: Icons.info,
                        color: LogcatColors.infoTextColor,
                        text: "Info",
                      ),
                      LogcatLevelFilterPopupMenuItem(
                        value: LogcatLevel.warning,
                        icon: Icons.warning,
                        color: LogcatColors.warningTextColor,
                        text: "Warning",
                      ),
                      LogcatLevelFilterPopupMenuItem(
                        value: LogcatLevel.error,
                        icon: Icons.error,
                        color: LogcatColors.errorTextColor,
                        text: "Error",
                      ),
                    ];
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
                padding: EdgeInsets.all(8),
                controller: _scrollController,
                itemCount: state.logs.length,
                itemBuilder: (context, index) {
                  return LogcatLine(line: state.logs[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
