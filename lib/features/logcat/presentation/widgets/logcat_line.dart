import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/entities/logcat_line_entity.dart';
import 'package:android_tools/features/logcat/presentation/core/logcat_level_extensions.dart';
import 'package:flutter/material.dart';

class LogcatLine extends StatelessWidget {
  static final _regex = RegExp(
    r'^(\d{2}-\d{2}) '
    r'(\d{2}:\d{2}:\d{2}\.\d{3})\s+'
    r'(\d+)\s+(\d+)\s+'
    r'([VDIWEF])\s+'
    r'(\S+)\s*:?\s*(.*)$',
  );

  final String line;
  final bool isShowProcessThreadIds;

  const LogcatLine({
    super.key,
    required this.line,
    required this.isShowProcessThreadIds,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _parseLogcatLine(line);

    if (parsed != null) {
      final textSpan = TextSpan(
        style: const TextStyle(fontFamily: "monospace", fontSize: 12),
        children: [
          WidgetSpan(
            child: SizedBox(
              width: 130,
              child: Text(
                '${parsed.dateTime.month.toString().padLeft(2, '0')}-'
                '${parsed.dateTime.day.toString().padLeft(2, '0')} '
                '${parsed.dateTime.hour.toString().padLeft(2, '0')}:'
                '${parsed.dateTime.minute.toString().padLeft(2, '0')}:'
                '${parsed.dateTime.second.toString().padLeft(2, '0')}.'
                '${parsed.dateTime.millisecond.toString().padLeft(3, '0')}  ',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          if (isShowProcessThreadIds)
            WidgetSpan(
              child: SizedBox(
                width: 100,
                child: Text(
                  textAlign: TextAlign.center,
                  '${parsed.processId}-${parsed.threadId} ',
                ),
              ),
            ),

          WidgetSpan(
            child: SizedBox(
              width: 140,
              child: Text(
                parsed.tag,
                maxLines: 1,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              alignment: Alignment.center,
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: parsed.level.backgroundColor()),
              child: Text(
                textAlign: TextAlign.center,
                parsed.level.name[0].toUpperCase(),
                style: TextStyle(
                  color: parsed.level.onBackgroundColor(),
                  fontSize: 14,
                  fontFamily: "Nothing",
                ),
              ),
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: parsed.message,
            style: TextStyle(color: parsed.level.textColor()),
          ),
        ],
      );

      return SelectableText.rich(textSpan, maxLines: 1);
    } else {
      return SelectableText(
        line,
        style: const TextStyle(fontFamily: "monospace", fontSize: 12),
      );
    }
  }

  LogcatLineEntity? _parseLogcatLine(String line) {
    final match = _regex.firstMatch(line);
    if (match == null) return null;

    try {
      final dateStr = match.group(1)!;
      final timeStr = match.group(2)!;
      final processId = int.parse(match.group(3)!);
      final threadId = int.parse(match.group(4)!);
      final levelLetter = match.group(5)!;
      final tag = match.group(6)!;
      final message = match.group(7)!;

      final now = DateTime.now();
      final dateTime = DateTime.parse('${now.year}-$dateStr $timeStr');

      final level = switch (levelLetter) {
        'V' => LogcatLevel.verbose,
        'D' => LogcatLevel.debug,
        'I' => LogcatLevel.info,
        'W' => LogcatLevel.warning,
        'E' => LogcatLevel.error,
        'F' => LogcatLevel.fatal,
        _ => LogcatLevel.verbose,
      };

      return LogcatLineEntity(
        dateTime: dateTime,
        level: level,
        processId: processId,
        threadId: threadId,
        tag: tag,
        message: message,
      );
    } catch (_) {
      return null;
    }
  }
}
