import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/presentation/logcat_bloc.dart';
import 'package:android_tools/features/logcat/presentation/widgets/logcat_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogcatAppbar extends StatefulWidget implements PreferredSizeWidget {
  const LogcatAppbar({super.key});

  @override
  State<LogcatAppbar> createState() => _LogcatAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _LogcatAppbarState extends State<LogcatAppbar> {
  static const _levels = [
    LogcatLevel.verbose,
    LogcatLevel.debug,
    LogcatLevel.info,
    LogcatLevel.warning,
    LogcatLevel.error,
  ];

  static const _levelLabels = {
    LogcatLevel.verbose: 'V',
    LogcatLevel.debug: 'D',
    LogcatLevel.info: 'I',
    LogcatLevel.warning: 'W',
    LogcatLevel.error: 'E',
  };

  static const _levelColors = {
    LogcatLevel.verbose: Color(0xFF6B707A),
    LogcatLevel.debug: Color(0xFF4A9EDD),
    LogcatLevel.info: Color(0xFF4CAF50),
    LogcatLevel.warning: Color(0xFFFFC107),
    LogcatLevel.error: Color(0xFFF44336),
  };

  // Map a single log line letter to the enum
  static const _letterToLevel = {
    'V': LogcatLevel.verbose,
    'D': LogcatLevel.debug,
    'I': LogcatLevel.info,
    'W': LogcatLevel.warning,
    'E': LogcatLevel.error,
    'F': LogcatLevel.fatal,
  };

  Map<LogcatLevel, int> _countLevels(List<String> logs) {
    final counts = <LogcatLevel, int>{
      for (final l in _levels) l: 0,
    };
    // Logcat threadtime format: "MM-DD HH:MM:SS.mmm PID TID LEVEL tag: msg"
    final re = RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\s+\d+\s+\d+\s+([VDIWEF])\s');
    for (final line in logs) {
      final m = re.firstMatch(line);
      if (m != null) {
        final level = _letterToLevel[m.group(1)];
        if (level != null && counts.containsKey(level)) {
          counts[level] = counts[level]! + 1;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return MoveWindow(
      child: AppBar(
        title: BlocBuilder<LogcatBloc, LogcatState>(
          builder: (context, state) {
            return Text(
              "${state.logs.length} lines",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          BlocBuilder<LogcatBloc, LogcatState>(
            builder: (context, state) {
              final counts = _countLevels(state.logs);
              final currentLevel = state.minimumLogLevel;

              return Row(
                spacing: 8,
                children: [
                  // Level filter pills
                  Row(
                    spacing: 4,
                    children: _levels.map((level) {
                      final isActive = level.index >= currentLevel.index;
                      final color = _levelColors[level]!;
                      final count = counts[level] ?? 0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          context.read<LogcatBloc>().add(
                            OnMinimumLogLevelChanged(minimumLogLevel: level),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isActive
                                  ? color.withValues(alpha: 0.5)
                                  : const Color(0xFF3A3B3F),
                            ),
                          ),
                          child: Row(
                            spacing: 4,
                            children: [
                              Text(
                                _levelLabels[level]!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? color
                                      : const Color(0xFF6B707A),
                                ),
                              ),
                              if (count > 0)
                                Text(
                                  count > 999 ? '999+' : '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isActive
                                        ? color.withValues(alpha: 0.8)
                                        : const Color(0xFF6B707A),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Pause / Resume
                  Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        FilledButton(
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              BeveledRectangleBorder(),
                            ),
                          ),
                          child: Icon(
                            state.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                          onPressed: () {
                            final event = state.isPaused
                                ? OnResumeLogcat()
                                : OnPauseLogcat();
                            context.read<LogcatBloc>().add(event);
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
                    color: const Color.fromARGB(255, 213, 36, 54),
                    icon: Icons.delete_outline_rounded,
                    onPressed: () =>
                        context.read<LogcatBloc>().add(OnClearLogcat()),
                  ),
                  IconButton(
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
