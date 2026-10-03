import {
  DeviceDiscoveryError,
  type DeviceService,
  type DeviceSummary,
} from '../domain/devices';

export type DemoScenario = 'devices' | 'empty' | 'error';

/** Deterministic scenarios shared by the explicit browser demo and behavior tests. */
export function createDemoDeviceService(scenario: DemoScenario): DeviceService {
  const devices: DeviceSummary[] = [
    {
      id: 'usb:1:2:18d1:4ee7',
      name: 'Pixel 9',
      serial: 'DEMO-A',
      manufacturer: 'Google',
      product: 'Pixel 9',
      vendorId: 0x18d1,
      productId: 0x4ee7,
      warning: null,
    },
    {
      id: 'usb:1:3:18d1:4ee7',
      name: 'Pixel 9',
      serial: 'DEMO-B',
      manufacturer: 'Google',
      product: 'Pixel 9',
      vendorId: 0x18d1,
      productId: 0x4ee7,
      warning: null,
    },
    {
      id: 'usb:1:4:04e8:6860',
      name: 'Android device',
      serial: null,
      manufacturer: null,
      product: null,
      vendorId: 0x04e8,
      productId: 0x6860,
      warning:
        'USB metadata is unavailable: access denied. Check USB permissions.',
    },
  ];
  return {
    async list() {
      if (scenario === 'error') {
        throw new DeviceDiscoveryError(
          'usb_unavailable',
          'Simulated USB discovery failure. Please retry.',
        );
      }
      return scenario === 'empty'
        ? []
        : devices.map((device) => ({ ...device }));
    },
  };
}
