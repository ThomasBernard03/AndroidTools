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
}
