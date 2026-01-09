import 'dart:io';

class ShellDatasource {
  String getAdbPath() {
    final execDir = Directory(Platform.resolvedExecutable).parent;
    final contents = execDir.parent;
    final resources = Directory("${contents.path}/Resources");
    return "${resources.path}/adb";
  }
}
