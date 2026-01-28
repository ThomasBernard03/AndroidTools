import 'package:equatable/equatable.dart';

class InstalledApplicationHistoryEntity extends Equatable {
  final int id;
  final String applicationName;
  final String applicationVersionName;
  final int applicationVersionCode;
  final String path;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InstalledApplicationHistoryEntity({
    required this.id,
    required this.applicationName,
    required this.applicationVersionName,
    required this.applicationVersionCode,
    required this.path,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        applicationName,
        applicationVersionName,
        applicationVersionCode,
        path,
        createdAt,
        updatedAt,
      ];
}
