import 'package:android_tools/presentation/logcat/logcat_bloc.dart';
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
                controller: _scrollController,
                itemCount: state.logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    state.logs[index],
                    style: const TextStyle(
                      fontFamily: "monospace",
                      fontSize: 12,
                    ),
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
