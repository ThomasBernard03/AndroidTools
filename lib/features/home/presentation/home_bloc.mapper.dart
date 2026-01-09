// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'home_bloc.dart';

class HomeStateMapper extends ClassMapperBase<HomeState> {
  HomeStateMapper._();

  static HomeStateMapper? _instance;
  static HomeStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HomeStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'HomeState';

  static String _$version(HomeState v) => v.version;
  static const Field<HomeState, String> _f$version = Field(
    'version',
    _$version,
    opt: true,
    def: "",
  );
  static Iterable<DeviceEntity> _$devices(HomeState v) => v.devices;
  static const Field<HomeState, Iterable<DeviceEntity>> _f$devices = Field(
    'devices',
    _$devices,
    opt: true,
    def: const [],
  );
  static DeviceEntity? _$selectedDevice(HomeState v) => v.selectedDevice;
  static const Field<HomeState, DeviceEntity> _f$selectedDevice = Field(
    'selectedDevice',
    _$selectedDevice,
    opt: true,
  );

  @override
  final MappableFields<HomeState> fields = const {
    #version: _f$version,
    #devices: _f$devices,
    #selectedDevice: _f$selectedDevice,
  };

  static HomeState _instantiate(DecodingData data) {
    return HomeState(
      version: data.dec(_f$version),
      devices: data.dec(_f$devices),
      selectedDevice: data.dec(_f$selectedDevice),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HomeState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HomeState>(map);
  }

  static HomeState fromJson(String json) {
    return ensureInitialized().decodeJson<HomeState>(json);
  }
}

mixin HomeStateMappable {
  String toJson() {
    return HomeStateMapper.ensureInitialized().encodeJson<HomeState>(
      this as HomeState,
    );
  }

  Map<String, dynamic> toMap() {
    return HomeStateMapper.ensureInitialized().encodeMap<HomeState>(
      this as HomeState,
    );
  }

  HomeStateCopyWith<HomeState, HomeState, HomeState> get copyWith =>
      _HomeStateCopyWithImpl<HomeState, HomeState>(
        this as HomeState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return HomeStateMapper.ensureInitialized().stringifyValue(
      this as HomeState,
    );
  }

  @override
  bool operator ==(Object other) {
    return HomeStateMapper.ensureInitialized().equalsValue(
      this as HomeState,
      other,
    );
  }

  @override
  int get hashCode {
    return HomeStateMapper.ensureInitialized().hashValue(this as HomeState);
  }
}

extension HomeStateValueCopy<$R, $Out> on ObjectCopyWith<$R, HomeState, $Out> {
  HomeStateCopyWith<$R, HomeState, $Out> get $asHomeState =>
      $base.as((v, t, t2) => _HomeStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HomeStateCopyWith<$R, $In extends HomeState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? version,
    Iterable<DeviceEntity>? devices,
    DeviceEntity? selectedDevice,
  });
  HomeStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _HomeStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HomeState, $Out>
    implements HomeStateCopyWith<$R, HomeState, $Out> {
  _HomeStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HomeState> $mapper =
      HomeStateMapper.ensureInitialized();
  @override
  $R call({
    String? version,
    Iterable<DeviceEntity>? devices,
    Object? selectedDevice = $none,
  }) => $apply(
    FieldCopyWithData({
      if (version != null) #version: version,
      if (devices != null) #devices: devices,
      if (selectedDevice != $none) #selectedDevice: selectedDevice,
    }),
  );
  @override
  HomeState $make(CopyWithData data) => HomeState(
    version: data.get(#version, or: $value.version),
    devices: data.get(#devices, or: $value.devices),
    selectedDevice: data.get(#selectedDevice, or: $value.selectedDevice),
  );

  @override
  HomeStateCopyWith<$R2, HomeState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _HomeStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

