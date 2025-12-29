// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'general_file_explorer_bloc.dart';

class GeneralFileExplorerStateMapper
    extends ClassMapperBase<GeneralFileExplorerState> {
  GeneralFileExplorerStateMapper._();

  static GeneralFileExplorerStateMapper? _instance;
  static GeneralFileExplorerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = GeneralFileExplorerStateMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'GeneralFileExplorerState';

  static List<FileEntry> _$files(GeneralFileExplorerState v) => v.files;
  static const Field<GeneralFileExplorerState, List<FileEntry>> _f$files =
      Field('files', _$files, opt: true, def: const []);
  static String _$path(GeneralFileExplorerState v) => v.path;
  static const Field<GeneralFileExplorerState, String> _f$path = Field(
    'path',
    _$path,
    opt: true,
    def: "/",
  );
  static DeviceEntity? _$device(GeneralFileExplorerState v) => v.device;
  static const Field<GeneralFileExplorerState, DeviceEntity> _f$device = Field(
    'device',
    _$device,
    opt: true,
  );
  static FileEntry? _$selectedFile(GeneralFileExplorerState v) =>
      v.selectedFile;
  static const Field<GeneralFileExplorerState, FileEntry> _f$selectedFile =
      Field('selectedFile', _$selectedFile, opt: true);
  static bool _$isLoading(GeneralFileExplorerState v) => v.isLoading;
  static const Field<GeneralFileExplorerState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<GeneralFileExplorerState> fields = const {
    #files: _f$files,
    #path: _f$path,
    #device: _f$device,
    #selectedFile: _f$selectedFile,
    #isLoading: _f$isLoading,
  };

  static GeneralFileExplorerState _instantiate(DecodingData data) {
    return GeneralFileExplorerState(
      files: data.dec(_f$files),
      path: data.dec(_f$path),
      device: data.dec(_f$device),
      selectedFile: data.dec(_f$selectedFile),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GeneralFileExplorerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GeneralFileExplorerState>(map);
  }

  static GeneralFileExplorerState fromJson(String json) {
    return ensureInitialized().decodeJson<GeneralFileExplorerState>(json);
  }
}

mixin GeneralFileExplorerStateMappable {
  String toJson() {
    return GeneralFileExplorerStateMapper.ensureInitialized()
        .encodeJson<GeneralFileExplorerState>(this as GeneralFileExplorerState);
  }

  Map<String, dynamic> toMap() {
    return GeneralFileExplorerStateMapper.ensureInitialized()
        .encodeMap<GeneralFileExplorerState>(this as GeneralFileExplorerState);
  }

  GeneralFileExplorerStateCopyWith<
    GeneralFileExplorerState,
    GeneralFileExplorerState,
    GeneralFileExplorerState
  >
  get copyWith =>
      _GeneralFileExplorerStateCopyWithImpl<
        GeneralFileExplorerState,
        GeneralFileExplorerState
      >(this as GeneralFileExplorerState, $identity, $identity);
  @override
  String toString() {
    return GeneralFileExplorerStateMapper.ensureInitialized().stringifyValue(
      this as GeneralFileExplorerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return GeneralFileExplorerStateMapper.ensureInitialized().equalsValue(
      this as GeneralFileExplorerState,
      other,
    );
  }

  @override
  int get hashCode {
    return GeneralFileExplorerStateMapper.ensureInitialized().hashValue(
      this as GeneralFileExplorerState,
    );
  }
}

extension GeneralFileExplorerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GeneralFileExplorerState, $Out> {
  GeneralFileExplorerStateCopyWith<$R, GeneralFileExplorerState, $Out>
  get $asGeneralFileExplorerState => $base.as(
    (v, t, t2) => _GeneralFileExplorerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GeneralFileExplorerStateCopyWith<
  $R,
  $In extends GeneralFileExplorerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, FileEntry, ObjectCopyWith<$R, FileEntry, FileEntry>>
  get files;
  $R call({
    List<FileEntry>? files,
    String? path,
    DeviceEntity? device,
    FileEntry? selectedFile,
    bool? isLoading,
  });
  GeneralFileExplorerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GeneralFileExplorerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GeneralFileExplorerState, $Out>
    implements
        GeneralFileExplorerStateCopyWith<$R, GeneralFileExplorerState, $Out> {
  _GeneralFileExplorerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GeneralFileExplorerState> $mapper =
      GeneralFileExplorerStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, FileEntry, ObjectCopyWith<$R, FileEntry, FileEntry>>
  get files => ListCopyWith(
    $value.files,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(files: v),
  );
  @override
  $R call({
    List<FileEntry>? files,
    String? path,
    Object? device = $none,
    Object? selectedFile = $none,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (files != null) #files: files,
      if (path != null) #path: path,
      if (device != $none) #device: device,
      if (selectedFile != $none) #selectedFile: selectedFile,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  GeneralFileExplorerState $make(CopyWithData data) => GeneralFileExplorerState(
    files: data.get(#files, or: $value.files),
    path: data.get(#path, or: $value.path),
    device: data.get(#device, or: $value.device),
    selectedFile: data.get(#selectedFile, or: $value.selectedFile),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  GeneralFileExplorerStateCopyWith<$R2, GeneralFileExplorerState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _GeneralFileExplorerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

