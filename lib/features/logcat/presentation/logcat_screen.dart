import 'package:android_tools/features/logcat/presentation/widgets/logcat_appbar.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_line.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: LogcatAppbar(),
        ),
        body: BlocListener<LogcatBloc, LogcatState>(
          listener: (context, state) {
            if (state.isSticky) {
              _scrollToBottom();
            }
          },
          child: BlocBuilder<LogcatBloc, LogcatState>(
            builder: (context, state) {
              return state.devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.read<LogcatBloc>().add(
                                OnRefreshDevices(),
                              );
                            },
                            child: Text("Refresh devices"),
                          ),
                          Text("Can't find any android devices"),
                        ],
                      ),
                    )
                  : BlocBuilder<LogcatBloc, LogcatState>(
                      builder: (context, state) {
                        return ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(8),
                          controller: _scrollController,
                          itemCount: state.logs
                              .take(state.maxLogcatLines)
                              .length,
                          itemBuilder: (context, index) {
                            return LogcatLine(
                              line: state.logs.reversed
                                  .take(state.maxLogcatLines)
                                  .toList()[index],
                            );
                          },
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
