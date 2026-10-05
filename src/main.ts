import { createApp } from 'vue';
import { createTauriFileService } from './features/files/infrastructure/tauriFileService';
import { createDemoFileService } from './features/files/infrastructure/demoFileService';
import { createTauriKeystoreExplorerService } from './features/keystore/infrastructure/tauriKeystoreExplorerService';
import { createDemoKeystoreExplorerService } from './features/keystore/infrastructure/demoKeystoreExplorerService';
import { initializeLocalLogging } from './shared/infrastructure/localLogging';
import { initializeCrashReporting } from './shared/infrastructure/crashReporting';
import { createTauriSettingsService } from './features/settings/infrastructure/tauriSettingsService';
import { createDemoSettingsService } from './features/settings/infrastructure/demoSettingsService';
import { createTauriSigningService } from './features/signing/infrastructure/tauriSigningService';
import { createDemoSigningService } from './features/signing/infrastructure/demoSigningService';
import { createTauriApkService } from './features/apk/infrastructure/tauriApkService';
import { createDemoApkService } from './features/apk/infrastructure/demoApkService';
import { createTauriKeystoreService } from './features/keystore/infrastructure/tauriKeystoreService';
import { createDemoKeystoreService } from './features/keystore/infrastructure/demoKeystoreService';
import App from './App.vue';
import './styles.css';
import { isTauri } from '@tauri-apps/api/core';
import { createTauriDeviceService } from './features/devices/infrastructure/tauriDeviceService';
import { createDemoDeviceService } from './features/devices/infrastructure/demoDeviceService';
import { createTauriAdbService } from './features/adb/infrastructure/tauriAdbService';
import { createDemoAdbService } from './features/adb/infrastructure/demoAdbService';
import {
  DeviceDiscoveryError,
  type DeviceService,
} from './features/devices/domain/devices';

const scenario = new URLSearchParams(window.location.search).get('demo');
const demo =
  import.meta.env.DEV &&
  (scenario === 'devices' || scenario === 'empty' || scenario === 'error');
const unavailable: DeviceService = {
  async list() {
    throw new DeviceDiscoveryError(
      'native_required',
      'USB discovery requires the desktop application. For a browser demo, open /?demo=devices with the development server.',
    );
  },
};
const deviceService = demo
  ? createDemoDeviceService(scenario)
  : isTauri()
    ? createTauriDeviceService()
    : unavailable;

const adbService = demo
  ? createDemoAdbService()
  : isTauri()
    ? createTauriAdbService()
    : undefined;
const keystoreService = demo
  ? createDemoKeystoreService(scenario === 'error')
  : isTauri()
    ? createTauriKeystoreService()
    : undefined;
const apkService = demo
  ? createDemoApkService(scenario === 'error')
  : isTauri()
    ? createTauriApkService()
    : undefined;
const app = createApp(App, {
  fileService: demo
    ? createDemoFileService(scenario === 'error')
    : isTauri()
      ? createTauriFileService()
      : undefined,
  keystoreExplorerService: demo
    ? createDemoKeystoreExplorerService(scenario === 'error')
    : isTauri()
      ? createTauriKeystoreExplorerService()
      : undefined,
  settingsService: demo
    ? createDemoSettingsService(scenario === 'error')
    : isTauri()
      ? createTauriSettingsService()
      : undefined,
  signingService: demo
    ? createDemoSigningService(scenario === 'error')
    : isTauri()
      ? createTauriSigningService()
      : undefined,
  deviceService,
  adbService,
  keystoreService,
  apkService,
  demo,
});
if (isTauri() && !demo) {
  initializeCrashReporting(app);
  initializeLocalLogging(app);
}
app.mount('#app');
