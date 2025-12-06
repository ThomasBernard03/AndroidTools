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

  @override
  final MappableFields<LogcatState> fields = const {#logs: _f$logs};

  static LogcatState _instantiate(DecodingData data) {
    return LogcatState(logs: data.dec(_f$logs));
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
  $R call({List<String>? logs});
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
  $R call({List<String>? logs}) =>
      $apply(FieldCopyWithData({if (logs != null) #logs: logs}));
  @override
  LogcatState $make(CopyWithData data) =>
      LogcatState(logs: data.get(#logs, or: $value.logs));

  @override
  LogcatStateCopyWith<$R2, LogcatState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LogcatStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

