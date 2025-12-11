// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'file_explorer_bloc.dart';

class FileExplorerStateMapper extends ClassMapperBase<FileExplorerState> {
  FileExplorerStateMapper._();

  static FileExplorerStateMapper? _instance;
  static FileExplorerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FileExplorerStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'FileExplorerState';

  @override
  final MappableFields<FileExplorerState> fields = const {};

  static FileExplorerState _instantiate(DecodingData data) {
    return FileExplorerState();
  }

  @override
  final Function instantiate = _instantiate;

  static FileExplorerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FileExplorerState>(map);
  }

  static FileExplorerState fromJson(String json) {
    return ensureInitialized().decodeJson<FileExplorerState>(json);
  }
}

mixin FileExplorerStateMappable {
  String toJson() {
    return FileExplorerStateMapper.ensureInitialized()
        .encodeJson<FileExplorerState>(this as FileExplorerState);
  }

  Map<String, dynamic> toMap() {
    return FileExplorerStateMapper.ensureInitialized()
        .encodeMap<FileExplorerState>(this as FileExplorerState);
  }

  FileExplorerStateCopyWith<
    FileExplorerState,
    FileExplorerState,
    FileExplorerState
  >
  get copyWith =>
      _FileExplorerStateCopyWithImpl<FileExplorerState, FileExplorerState>(
        this as FileExplorerState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FileExplorerStateMapper.ensureInitialized().stringifyValue(
      this as FileExplorerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return FileExplorerStateMapper.ensureInitialized().equalsValue(
      this as FileExplorerState,
      other,
    );
  }

  @override
  int get hashCode {
    return FileExplorerStateMapper.ensureInitialized().hashValue(
      this as FileExplorerState,
    );
  }
}

extension FileExplorerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FileExplorerState, $Out> {
  FileExplorerStateCopyWith<$R, FileExplorerState, $Out>
  get $asFileExplorerState => $base.as(
    (v, t, t2) => _FileExplorerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class FileExplorerStateCopyWith<
  $R,
  $In extends FileExplorerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  FileExplorerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FileExplorerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FileExplorerState, $Out>
    implements FileExplorerStateCopyWith<$R, FileExplorerState, $Out> {
  _FileExplorerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FileExplorerState> $mapper =
      FileExplorerStateMapper.ensureInitialized();
  @override
  $R call() => $apply(FieldCopyWithData({}));
  @override
  FileExplorerState $make(CopyWithData data) => FileExplorerState();

  @override
  FileExplorerStateCopyWith<$R2, FileExplorerState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FileExplorerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

