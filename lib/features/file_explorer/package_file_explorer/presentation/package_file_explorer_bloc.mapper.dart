// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'package_file_explorer_bloc.dart';

class PackageFileExplorerStateMapper
    extends ClassMapperBase<PackageFileExplorerState> {
  PackageFileExplorerStateMapper._();

  static PackageFileExplorerStateMapper? _instance;
  static PackageFileExplorerStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = PackageFileExplorerStateMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'PackageFileExplorerState';

  static Iterable<String> _$packages(PackageFileExplorerState v) => v.packages;
  static const Field<PackageFileExplorerState, Iterable<String>> _f$packages =
      Field('packages', _$packages, opt: true, def: const []);
  static String? _$selectedPackage(PackageFileExplorerState v) =>
      v.selectedPackage;
  static const Field<PackageFileExplorerState, String> _f$selectedPackage =
      Field('selectedPackage', _$selectedPackage, opt: true);
  static List<FileEntry> _$files(PackageFileExplorerState v) => v.files;
  static const Field<PackageFileExplorerState, List<FileEntry>> _f$files =
      Field('files', _$files, opt: true, def: const []);
  static String _$path(PackageFileExplorerState v) => v.path;
  static const Field<PackageFileExplorerState, String> _f$path = Field(
    'path',
    _$path,
    opt: true,
    def: "/",
  );
  static DeviceEntity? _$device(PackageFileExplorerState v) => v.device;
  static const Field<PackageFileExplorerState, DeviceEntity> _f$device = Field(
    'device',
    _$device,
    opt: true,
  );
  static FileEntry? _$selectedFile(PackageFileExplorerState v) =>
      v.selectedFile;
  static const Field<PackageFileExplorerState, FileEntry> _f$selectedFile =
      Field('selectedFile', _$selectedFile, opt: true);
  static bool _$isLoading(PackageFileExplorerState v) => v.isLoading;
  static const Field<PackageFileExplorerState, bool> _f$isLoading = Field(
    'isLoading',
    _$isLoading,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<PackageFileExplorerState> fields = const {
    #packages: _f$packages,
    #selectedPackage: _f$selectedPackage,
    #files: _f$files,
    #path: _f$path,
    #device: _f$device,
    #selectedFile: _f$selectedFile,
    #isLoading: _f$isLoading,
  };

  static PackageFileExplorerState _instantiate(DecodingData data) {
    return PackageFileExplorerState(
      packages: data.dec(_f$packages),
      selectedPackage: data.dec(_f$selectedPackage),
      files: data.dec(_f$files),
      path: data.dec(_f$path),
      device: data.dec(_f$device),
      selectedFile: data.dec(_f$selectedFile),
      isLoading: data.dec(_f$isLoading),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PackageFileExplorerState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PackageFileExplorerState>(map);
  }

  static PackageFileExplorerState fromJson(String json) {
    return ensureInitialized().decodeJson<PackageFileExplorerState>(json);
  }
}

mixin PackageFileExplorerStateMappable {
  String toJson() {
    return PackageFileExplorerStateMapper.ensureInitialized()
        .encodeJson<PackageFileExplorerState>(this as PackageFileExplorerState);
  }

  Map<String, dynamic> toMap() {
    return PackageFileExplorerStateMapper.ensureInitialized()
        .encodeMap<PackageFileExplorerState>(this as PackageFileExplorerState);
  }

  PackageFileExplorerStateCopyWith<
    PackageFileExplorerState,
    PackageFileExplorerState,
    PackageFileExplorerState
  >
  get copyWith =>
      _PackageFileExplorerStateCopyWithImpl<
        PackageFileExplorerState,
        PackageFileExplorerState
      >(this as PackageFileExplorerState, $identity, $identity);
  @override
  String toString() {
    return PackageFileExplorerStateMapper.ensureInitialized().stringifyValue(
      this as PackageFileExplorerState,
    );
  }

  @override
  bool operator ==(Object other) {
    return PackageFileExplorerStateMapper.ensureInitialized().equalsValue(
      this as PackageFileExplorerState,
      other,
    );
  }

  @override
  int get hashCode {
    return PackageFileExplorerStateMapper.ensureInitialized().hashValue(
      this as PackageFileExplorerState,
    );
  }
}

extension PackageFileExplorerStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PackageFileExplorerState, $Out> {
  PackageFileExplorerStateCopyWith<$R, PackageFileExplorerState, $Out>
  get $asPackageFileExplorerState => $base.as(
    (v, t, t2) => _PackageFileExplorerStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PackageFileExplorerStateCopyWith<
  $R,
  $In extends PackageFileExplorerState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, FileEntry, ObjectCopyWith<$R, FileEntry, FileEntry>>
  get files;
  $R call({
    Iterable<String>? packages,
    String? selectedPackage,
    List<FileEntry>? files,
    String? path,
    DeviceEntity? device,
    FileEntry? selectedFile,
    bool? isLoading,
  });
  PackageFileExplorerStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PackageFileExplorerStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PackageFileExplorerState, $Out>
    implements
        PackageFileExplorerStateCopyWith<$R, PackageFileExplorerState, $Out> {
  _PackageFileExplorerStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PackageFileExplorerState> $mapper =
      PackageFileExplorerStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, FileEntry, ObjectCopyWith<$R, FileEntry, FileEntry>>
  get files => ListCopyWith(
    $value.files,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(files: v),
  );
  @override
  $R call({
    Iterable<String>? packages,
    Object? selectedPackage = $none,
    List<FileEntry>? files,
    String? path,
    Object? device = $none,
    Object? selectedFile = $none,
    bool? isLoading,
  }) => $apply(
    FieldCopyWithData({
      if (packages != null) #packages: packages,
      if (selectedPackage != $none) #selectedPackage: selectedPackage,
      if (files != null) #files: files,
      if (path != null) #path: path,
      if (device != $none) #device: device,
      if (selectedFile != $none) #selectedFile: selectedFile,
      if (isLoading != null) #isLoading: isLoading,
    }),
  );
  @override
  PackageFileExplorerState $make(CopyWithData data) => PackageFileExplorerState(
    packages: data.get(#packages, or: $value.packages),
    selectedPackage: data.get(#selectedPackage, or: $value.selectedPackage),
    files: data.get(#files, or: $value.files),
    path: data.get(#path, or: $value.path),
    device: data.get(#device, or: $value.device),
    selectedFile: data.get(#selectedFile, or: $value.selectedFile),
    isLoading: data.get(#isLoading, or: $value.isLoading),
  );

  @override
  PackageFileExplorerStateCopyWith<$R2, PackageFileExplorerState, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PackageFileExplorerStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

