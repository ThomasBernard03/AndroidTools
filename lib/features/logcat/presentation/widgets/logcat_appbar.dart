import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatAppbar extends StatefulWidget implements PreferredSizeWidget {
  const LogcatAppbar({super.key});

  @override
  State<LogcatAppbar> createState() => _LogcatAppbarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _LogcatAppbarState extends State<LogcatAppbar> {
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
              return Text(state.logs.length.toString());
            },
          ),
          Row(
            children: [
              Row(
                spacing: 8,
                children: [
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
                  IconButton(
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    icon: Icon(Icons.filter_alt_off_rounded),
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
