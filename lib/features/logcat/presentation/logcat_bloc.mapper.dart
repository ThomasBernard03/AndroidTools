// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'logcat_bloc.dart';

class LogcatStateMapper extends ClassMapperBase<LogcatState> {
  LogcatStateMapper._();

  static LogcatStateMapper? _instance;
  static LogcatStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LogcatStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LogcatState';

  static List<String> _$logs(LogcatState v) => v.logs;
  static const Field<LogcatState, List<String>> _f$logs = Field(
    'logs',
    _$logs,
    opt: true,
    def: const [],
  );
  static bool _$isSticky(LogcatState v) => v.isSticky;
  static const Field<LogcatState, bool> _f$isSticky = Field(
    'isSticky',
    _$isSticky,
    opt: true,
    def: true,
  );
  static bool _$isPaused(LogcatState v) => v.isPaused;
  static const Field<LogcatState, bool> _f$isPaused = Field(
    'isPaused',
    _$isPaused,
    opt: true,
    def: false,
  );
  static LogcatLevel _$minimumLogLevel(LogcatState v) => v.minimumLogLevel;
  static const Field<LogcatState, LogcatLevel> _f$minimumLogLevel = Field(
    'minimumLogLevel',
    _$minimumLogLevel,
    opt: true,
    def: LogcatLevel.debug,
  );
  static DeviceEntity? _$selectedDevice(LogcatState v) => v.selectedDevice;
  static const Field<LogcatState, DeviceEntity> _f$selectedDevice = Field(
    'selectedDevice',
    _$selectedDevice,
    opt: true,
  );
  static List<ProcessEntity> _$processes(LogcatState v) => v.processes;
  static const Field<LogcatState, List<ProcessEntity>> _f$processes = Field(
    'processes',
    _$processes,
    opt: true,
    def: const [],
  );
  static ProcessEntity? _$selectedProcess(LogcatState v) => v.selectedProcess;
  static const Field<LogcatState, ProcessEntity> _f$selectedProcess = Field(
    'selectedProcess',
    _$selectedProcess,
    opt: true,
  );

  @override
  final MappableFields<LogcatState> fields = const {
    #logs: _f$logs,
    #isSticky: _f$isSticky,
    #isPaused: _f$isPaused,
    #minimumLogLevel: _f$minimumLogLevel,
    #selectedDevice: _f$selectedDevice,
    #processes: _f$processes,
    #selectedProcess: _f$selectedProcess,
  };

  static LogcatState _instantiate(DecodingData data) {
    return LogcatState(
      logs: data.dec(_f$logs),
      isSticky: data.dec(_f$isSticky),
      isPaused: data.dec(_f$isPaused),
      minimumLogLevel: data.dec(_f$minimumLogLevel),
      selectedDevice: data.dec(_f$selectedDevice),
      processes: data.dec(_f$processes),
      selectedProcess: data.dec(_f$selectedProcess),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LogcatState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LogcatState>(map);
  }

  static LogcatState fromJson(String json) {
    return ensureInitialized().decodeJson<LogcatState>(json);
  }
}

mixin LogcatStateMappable {
  String toJson() {
    return LogcatStateMapper.ensureInitialized().encodeJson<LogcatState>(
      this as LogcatState,
    );
  }

  Map<String, dynamic> toMap() {
    return LogcatStateMapper.ensureInitialized().encodeMap<LogcatState>(
      this as LogcatState,
    );
  }

  LogcatStateCopyWith<LogcatState, LogcatState, LogcatState> get copyWith =>
      _LogcatStateCopyWithImpl<LogcatState, LogcatState>(
        this as LogcatState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LogcatStateMapper.ensureInitialized().stringifyValue(
      this as LogcatState,
    );
  }

  @override
  bool operator ==(Object other) {
    return LogcatStateMapper.ensureInitialized().equalsValue(
      this as LogcatState,
      other,
    );
  }

  @override
  int get hashCode {
    return LogcatStateMapper.ensureInitialized().hashValue(this as LogcatState);
  }
}

extension LogcatStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LogcatState, $Out> {
  LogcatStateCopyWith<$R, LogcatState, $Out> get $asLogcatState =>
      $base.as((v, t, t2) => _LogcatStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LogcatStateCopyWith<$R, $In extends LogcatState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get logs;
  ListCopyWith<
    $R,
    ProcessEntity,
    ObjectCopyWith<$R, ProcessEntity, ProcessEntity>
  >
  get processes;
  $R call({
    List<String>? logs,
    bool? isSticky,
    bool? isPaused,
    LogcatLevel? minimumLogLevel,
    DeviceEntity? selectedDevice,
    List<ProcessEntity>? processes,
    ProcessEntity? selectedProcess,
  });
  LogcatStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LogcatStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LogcatState, $Out>
    implements LogcatStateCopyWith<$R, LogcatState, $Out> {
  _LogcatStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LogcatState> $mapper =
      LogcatStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get logs =>
      ListCopyWith(
        $value.logs,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(logs: v),
      );
  @override
  ListCopyWith<
    $R,
    ProcessEntity,
    ObjectCopyWith<$R, ProcessEntity, ProcessEntity>
  >
  get processes => ListCopyWith(
    $value.processes,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(processes: v),
  );
  @override
  $R call({
    List<String>? logs,
    bool? isSticky,
    bool? isPaused,
    LogcatLevel? minimumLogLevel,
    Object? selectedDevice = $none,
    List<ProcessEntity>? processes,
    Object? selectedProcess = $none,
  }) => $apply(
    FieldCopyWithData({
      if (logs != null) #logs: logs,
      if (isSticky != null) #isSticky: isSticky,
      if (isPaused != null) #isPaused: isPaused,
      if (minimumLogLevel != null) #minimumLogLevel: minimumLogLevel,
      if (selectedDevice != $none) #selectedDevice: selectedDevice,
      if (processes != null) #processes: processes,
      if (selectedProcess != $none) #selectedProcess: selectedProcess,
    }),
  );
  @override
  LogcatState $make(CopyWithData data) => LogcatState(
    logs: data.get(#logs, or: $value.logs),
    isSticky: data.get(#isSticky, or: $value.isSticky),
    isPaused: data.get(#isPaused, or: $value.isPaused),
    minimumLogLevel: data.get(#minimumLogLevel, or: $value.minimumLogLevel),
    selectedDevice: data.get(#selectedDevice, or: $value.selectedDevice),
    processes: data.get(#processes, or: $value.processes),
    selectedProcess: data.get(#selectedProcess, or: $value.selectedProcess),
  );

  @override
  LogcatStateCopyWith<$R2, LogcatState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LogcatStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

