import 'package:android_tools/presentation/logcat/logcat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatScreen extends StatelessWidget {
  LogcatScreen({super.key});

  final bloc = LogcatBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc..add(OnStartListeningLogcat()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Logcat"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Clear logs",
              onPressed: () {
                bloc.add(OnClearLogcat()); // Envoi de l’événement Clear
              },
            ),
          ],
        ),
        body: BlocBuilder<LogcatBloc, LogcatState>(
          builder: (context, state) {
            return ListView.builder(
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                return Text(
                  state.logs[index],
                  style: const TextStyle(fontFamily: "monospace", fontSize: 12),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
