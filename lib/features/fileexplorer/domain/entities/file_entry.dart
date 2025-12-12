import 'package:android_tools/features/fileexplorer/domain/entities/file_type.dart';

class FileEntry {
  final FileType type;
  final String permissions;
  final int? links;
  final String? owner;
  final String? group;
  final int? size;
  final DateTime? date;
  final String name;
  final String? symlinkTarget;

  FileEntry({
    required this.type,
    required this.permissions,
    required this.name,
    this.links,
    this.owner,
    this.group,
    this.size,
    this.date,
    this.symlinkTarget,
  });
}
