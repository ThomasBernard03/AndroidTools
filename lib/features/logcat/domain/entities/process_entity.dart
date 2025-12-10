import 'package:equatable/equatable.dart';

class ProcessEntity extends Equatable {
  final int processId;
  final String packageName;

  const ProcessEntity({required this.processId, required this.packageName});

  @override
  List<Object?> get props => [packageName, processId];
}
