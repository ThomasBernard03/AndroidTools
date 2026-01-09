import 'package:android_tools/features/logcat/presentation/widgets/logcat_appbar.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_filter_drawer.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_line.dart';
import 'package:android_tools/shared/presentation/refresh_device_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        floatingActionButton: BlocBuilder<LogcatBloc, LogcatState>(
          builder: (context, state) {
            return FloatingActionButton(
              backgroundColor: state.isSticky
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              foregroundColor: state.isSticky
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
              onPressed: () {
                context.read<LogcatBloc>().add(
                  OnToggleIsSticky(isSticky: !state.isSticky),
                );
              },
              child: Icon(Icons.arrow_downward_rounded),
            );
          },
        ),
        endDrawer: LogcatFilterDrawer(),
        appBar: LogcatAppbar(),
        body: BlocListener<LogcatBloc, LogcatState>(
          listener: (context, state) {
            if (state.isSticky) {
              _scrollToBottom();
            }
          },
          child: BlocBuilder<LogcatBloc, LogcatState>(
            builder: (context, state) {
              return state.selectedDevice == null
                  ? Center(
                      child: RefreshDeviceButton(
                        onPressed: () =>
                            context.read<LogcatBloc>().add(OnRefreshDevices()),
                      ),
                    )
                  : NotificationListener<UserScrollNotification>(
                      onNotification: (notification) {
                        if (notification.direction == ScrollDirection.reverse &&
                            state.isSticky) {
                          bloc.add(OnToggleIsSticky(isSticky: false));
                        }
                        return false;
                      },
                      child: ListView.builder(
                        prototypeItem: state.logs.isEmpty
                            ? null
                            : LogcatLine(
                                line: state.logs.last,
                                isShowProcessThreadIds:
                                    state.isShowProcessThreadIds,
                              ),
                        reverse: true,
                        padding: EdgeInsets.all(8),
                        controller: _scrollController,
                        itemCount: state.logs.length,
                        itemBuilder: (context, index) {
                          final line = state.logs.reversed.elementAt(index);
                          return LogcatLine(
                            line: line,
                            isShowProcessThreadIds:
                                state.isShowProcessThreadIds,
                          );
                        },
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}
