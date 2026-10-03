import { AdbError, type AdbService } from '../domain/adb';

/** Explicit simulation: the second phone needs authorization; the third lacks USB access. */
export function createDemoAdbService(): AdbService {
  return {
    async read(id) {
      if (id === 'usb:1:3:18d1:4ee7') {
        throw new AdbError(
          'unauthorized',
          'Simulated authorization required. Unlock your phone and allow USB debugging, then retry.',
        );
      }
      if (id !== 'usb:1:2:18d1:4ee7') {
        throw new AdbError(
          'usb_access',
          'Simulated USB access failure. Check USB permissions and retry.',
        );
      }
      return {
        manufacturer: 'Google',
        model: 'Pixel 9',
        androidVersion: '16',
        apiLevel: '36',
        securityPatch: '2026-09-05',
        buildId: 'DEMO-BUILD',
        architecture: 'arm64-v8a',
        batteryPercent: 82,
        batteryStatus: 'Charging',
        warning: null,
      };
    },
    async disconnect() {},
  };
}
