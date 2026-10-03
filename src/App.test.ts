import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import App from './App.vue';
import { createDemoDeviceService } from './features/devices/infrastructure/demoDeviceService';
import { createDemoAdbService } from './features/adb/infrastructure/demoAdbService';

describe('Application composition', () => {
  it('opens each planned tool and preserves the device connection when returning to the overview', async () => {
    const wrapper = mount(App, {
      props: {
        deviceService: createDemoDeviceService('devices'),
        adbService: createDemoAdbService(),
        demo: true,
      },
    });
    try {
      await flushPromises();
      await wrapper.get('aside select').setValue('usb:1:4:04e8:6860');
      await flushPromises();
      const connectionStatus = wrapper
        .get('[aria-label="Device connection status"]')
        .text();
      const navigation = wrapper.get('nav[aria-label="Workspace"]');
      for (const label of [
        'File explorer',
        'Logcat',
        'APK analysis',
        'APK generation',
        'APK signing',
      ]) {
        const button = navigation
          .findAll('button')
          .find((entry) => entry.text() === label)!;
        await button.trigger('click');
        expect(navigation.findAll('[aria-current="page"]')).toHaveLength(1);
        expect(button.attributes('aria-current')).toBe('page');
        expect(wrapper.get('main h2').text()).toBe(label);
        expect(wrapper.get('main').text()).toContain('Coming soon');
        expect(wrapper.get('main header').text()).toContain(label);
        expect(
          wrapper.get<HTMLSelectElement>('aside select').element.value,
        ).toBe('usb:1:4:04e8:6860');
      }
      await navigation.findAll('button')[0]!.trigger('click');
      expect(wrapper.get('main h2').text()).toBe('Android device');
      expect(wrapper.get('main dl').text()).toContain('usb:1:4:04e8:6860');
      expect(
        wrapper.get('[aria-label="Device connection status"]').text(),
      ).toBe(connectionStatus);
      expect(wrapper.get('main').text()).not.toContain('Coming soon');
    } finally {
      wrapper.unmount();
    }
  });

  it('keeps planned tools accessible without a connected device', async () => {
    const wrapper = mount(App, {
      props: { deviceService: createDemoDeviceService('empty') },
    });
    try {
      await flushPromises();
      const navigation = wrapper.get('nav[aria-label="Workspace"]');
      for (const button of navigation.findAll('button').slice(1)) {
        await button.trigger('click');
        expect(wrapper.get('main h2').text()).toBe(button.text());
        expect(wrapper.get('main').text()).toContain('Coming soon');
      }
    } finally {
      wrapper.unmount();
    }
  });

  it('automatically connects ADB for the first device and shows authorization failures without stale Android data', async () => {
    const wrapper = mount(App, {
      props: {
        deviceService: createDemoDeviceService('devices'),
        adbService: createDemoAdbService(),
        demo: true,
      },
    });
    try {
      await flushPromises();
      expect(wrapper.get<HTMLSelectElement>('aside select').element.value).toBe(
        'usb:1:2:18d1:4ee7',
      );
      const status = () =>
        wrapper.get('[aria-label="Device connection status"]').text();
      const panel = () => wrapper.get('[aria-labelledby="android-info-title"]');
      expect(status()).toContain('ADB: Connected');
      expect(panel().text()).toContain('Simulated Android information');
      expect(panel().text()).toContain('82%');
      expect(panel().text()).toContain('2026-09-05');
      await panel().get('button').trigger('click');
      await flushPromises();
      expect(status()).toContain('ADB: Connected');
      await wrapper.get('aside select').setValue('usb:1:3:18d1:4ee7');
      await flushPromises();
      expect(status()).toContain('ADB: Authorization required');
      expect(panel().get('[role="alert"]').text()).toContain(
        'allow USB debugging',
      );
      expect(panel().find('dl').exists()).toBe(false);
      expect(panel().get('button').text()).toBe('Retry ADB connection');
      await wrapper.get('aside select').setValue('');
      await flushPromises();
      expect(
        wrapper.find('[aria-labelledby="android-info-title"]').exists(),
      ).toBe(false);
      expect(status()).not.toContain('ADB:');
    } finally {
      wrapper.unmount();
    }
  });
  it('runs with explicit simulated devices without a native runtime or phone', async () => {
    const wrapper = mount(App, {
      props: { deviceService: createDemoDeviceService('devices'), demo: true },
    });
    try {
      await flushPromises();
      expect(wrapper.get('main h2').text()).toBe('Pixel 9');
      expect(wrapper.get('[role="note"]').text()).toContain('Demo mode');
      expect(wrapper.findAll('option')).toHaveLength(4);
      expect(
        wrapper.get('[aria-label="Device connection status"]').text(),
      ).toContain('Demo — simulated connection');
    } finally {
      wrapper.unmount();
    }
  });

  it('shows the sidebar selection in the workspace and clears it after disconnection', async () => {
    let devices = await createDemoDeviceService('devices').list();
    const wrapper = mount(App, {
      props: { deviceService: { list: async () => devices } },
    });
    try {
      await flushPromises();
      expect(wrapper.get('main h2').text()).toBe('Pixel 9');
      const status = () =>
        wrapper
          .get('[aria-label="Device connection status"]')
          .text()
          .replace(/\s+/g, ' ');
      expect(status()).toContain('Pixel 9 — DEMO-A');
      await wrapper.get('aside select').setValue('usb:1:3:18d1:4ee7');
      expect(status()).toContain('Pixel 9 — DEMO-B');
      expect(status()).toContain('USB');
      expect(status()).toContain('ADB: Not checked');
      await wrapper.get('aside select').setValue('usb:1:4:04e8:6860');
      expect(status()).toContain('Android device — usb:1:4:04e8:6860');
      expect(status()).not.toContain('DEMO-B');
      await wrapper.get('aside select').setValue('usb:1:3:18d1:4ee7');
      expect(wrapper.get('main h2').text()).toBe('Pixel 9');
      expect(wrapper.get('main dl').text()).toContain('DEMO-B');
      expect(wrapper.get('main dl').text()).not.toContain('DEMO-A');
      devices = [];
      await wrapper.get('aside button').trigger('click');
      await flushPromises();
      expect(wrapper.get('main').text()).toContain('Start with a device');
      expect(wrapper.find('main dl').exists()).toBe(false);
      expect(status()).toContain('No device selected');
      expect(status()).not.toContain('DEMO-B');
      expect(status()).not.toContain('ADB:');
    } finally {
      wrapper.unmount();
    }
  });
});
