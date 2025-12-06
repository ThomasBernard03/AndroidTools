import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AdbBundled {
  static Future<String> prepareAdb() async {
    final dir = await getTemporaryDirectory();

    final adbPath = Platform.isWindows
        ? '${dir.path}/adb.exe'
        : '${dir.path}/adb';

    final assetPath = Platform.isWindows
        ? 'assets/adb/windows/adb.exe'
        : Platform.isMacOS
        ? 'assets/adb/macos/adb'
        : 'assets/adb/linux/adb';

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final file = File(adbPath);
    await file.writeAsBytes(bytes, flush: true);

    // Donner le droit d’exécution sous Unix
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', adbPath]);
    }

    return adbPath;
  }
}
