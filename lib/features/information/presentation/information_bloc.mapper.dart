// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'information_bloc.dart';

class InformationStateMapper extends ClassMapperBase<InformationState> {
  InformationStateMapper._();

  static InformationStateMapper? _instance;
  static InformationStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = InformationStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'InformationState';

  static DeviceInformationEntity? _$deviceInformation(InformationState v) =>
      v.deviceInformation;
  static const Field<InformationState, DeviceInformationEntity>
  _f$deviceInformation = Field(
    'deviceInformation',
    _$deviceInformation,
    opt: true,
  );
  static DeviceEntity? _$device(InformationState v) => v.device;
  static const Field<InformationState, DeviceEntity> _f$device = Field(
    'device',
    _$device,
    opt: true,
  );

  @override
  final MappableFields<InformationState> fields = const {
    #deviceInformation: _f$deviceInformation,
    #device: _f$device,
  };

  static InformationState _instantiate(DecodingData data) {
    return InformationState(
      deviceInformation: data.dec(_f$deviceInformation),
      device: data.dec(_f$device),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static InformationState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<InformationState>(map);
  }

  static InformationState fromJson(String json) {
    return ensureInitialized().decodeJson<InformationState>(json);
  }
}

mixin InformationStateMappable {
  String toJson() {
    return InformationStateMapper.ensureInitialized()
        .encodeJson<InformationState>(this as InformationState);
  }

  Map<String, dynamic> toMap() {
    return InformationStateMapper.ensureInitialized()
        .encodeMap<InformationState>(this as InformationState);
  }

  InformationStateCopyWith<InformationState, InformationState, InformationState>
  get copyWith =>
      _InformationStateCopyWithImpl<InformationState, InformationState>(
        this as InformationState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return InformationStateMapper.ensureInitialized().stringifyValue(
      this as InformationState,
    );
  }

  @override
  bool operator ==(Object other) {
    return InformationStateMapper.ensureInitialized().equalsValue(
      this as InformationState,
      other,
    );
  }

  @override
  int get hashCode {
    return InformationStateMapper.ensureInitialized().hashValue(
      this as InformationState,
    );
  }
}

extension InformationStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, InformationState, $Out> {
  InformationStateCopyWith<$R, InformationState, $Out>
  get $asInformationState =>
      $base.as((v, t, t2) => _InformationStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class InformationStateCopyWith<$R, $In extends InformationState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({DeviceInformationEntity? deviceInformation, DeviceEntity? device});
  InformationStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _InformationStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, InformationState, $Out>
    implements InformationStateCopyWith<$R, InformationState, $Out> {
  _InformationStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<InformationState> $mapper =
      InformationStateMapper.ensureInitialized();
  @override
  $R call({Object? deviceInformation = $none, Object? device = $none}) =>
      $apply(
        FieldCopyWithData({
          if (deviceInformation != $none) #deviceInformation: deviceInformation,
          if (device != $none) #device: device,
        }),
      );
  @override
  InformationState $make(CopyWithData data) => InformationState(
    deviceInformation: data.get(
      #deviceInformation,
      or: $value.deviceInformation,
    ),
    device: data.get(#device, or: $value.device),
  );

  @override
  InformationStateCopyWith<$R2, InformationState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _InformationStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

