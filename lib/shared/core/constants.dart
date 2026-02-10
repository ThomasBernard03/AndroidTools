import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

class Constants {
  static Future<Directory> getApplicationLogsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final logDirectory = Directory(p.join(directory.path, 'logs'));

    if (!await logDirectory.exists()) {
      await logDirectory.create(recursive: true);
    }

    return logDirectory;
  }

  static String getAdbPath() {
    if (Platform.isMacOS) {
      final execDir = Directory(Platform.resolvedExecutable).parent;
      final contents = execDir.parent;
      final resources = Directory("${contents.path}/Resources");
      return "${resources.path}/adb";
    } else if (Platform.isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent;
      return "${execDir.path}/adb.exe";
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static String getAaptPath() {
    if (Platform.isMacOS) {
      final execDir = Directory(Platform.resolvedExecutable).parent;
      final contents = execDir.parent;
      final resources = Directory("${contents.path}/Resources");
      return "${resources.path}/aapt";
    } else if (Platform.isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent;
      return "${execDir.path}/aapt.exe";
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  static const environmentGitRepositoryUrl = "GIT_REPOSITORY_URL";
  static const environmentIssueUrl = "ISSUE_URL";
  static const environmentSentryDsn = "SENTRY_DSN";
  static const environmentAutoUpdaterFeedUrl = "AUTO_UPDATER_FEED_URL";
}
