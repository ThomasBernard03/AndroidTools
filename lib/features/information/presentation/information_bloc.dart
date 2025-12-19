import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/usecases/get_device_information_usecase.dart';
import 'package:android_tools/main.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/usecases/listen_selected_device_usecase.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

part 'information_event.dart';
part 'information_state.dart';
part 'information_bloc.mapper.dart';

class InformationBloc extends Bloc<InformationEvent, InformationState> {
  final Logger _logger = getIt.get();
  final ListenSelectedDeviceUsecase _listenSelectedDeviceUsecase = getIt.get();
  final GetDeviceInformationUsecase _getDeviceInformationUsecase = getIt.get();

  InformationBloc() : super(InformationState()) {
    on<OnAppearing>((event, emit) async {
      await emit.onEach<DeviceEntity?>(
        _listenSelectedDeviceUsecase(),
        onData: (device) async {
          if (device == null) {
            _logger.i("Selected device is null, can't get information");
            return;
          }

          final information = await _getDeviceInformationUsecase(
            device.deviceId,
          );
          _logger.d(information);
          emit(state.copyWith(deviceInformation: information));
        },
      );
    });
  }
}
