import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';
import 'package:equatable/equatable.dart';

class FileEntry extends Equatable {
  final FileType type;
  final String permissions;
  final int? links;
  final String? owner;
  final String? group;
  final int? size;
  final DateTime? date;
  final String name;
  final String? symlinkTarget;

  const FileEntry({
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

  @override
  List<Object?> get props => [name];
}
