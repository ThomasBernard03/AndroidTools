import { createApp } from 'vue';
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
createApp(App, { deviceService, adbService, demo }).mount('#app');
