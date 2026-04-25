import 'package:android_tools/features/home/presentation/home_bloc.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceBox extends StatelessWidget {
  final HomeState state;
  const DeviceBox({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasDevice = state.selectedDevice != null;
    final devices = state.devices;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasDevice
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF6B707A),
              boxShadow: hasDevice
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Text(
                    "No device",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<DeviceEntity>(
                      isDense: true,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      value: state.selectedDevice,
                      items: devices
                          .map(
                            (device) => DropdownMenuItem<DeviceEntity>(
                              value: device,
                              child: Text(
                                device.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (device) {
                        if (device == null) return;
                        // Find HomeBloc in the widget tree
                        context.read<HomeBloc>().add(
                          OnDeviceSelected(device: device),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
