import { mount } from '@vue/test-utils';
import { describe, expect, it } from 'vitest';
import { createDemoDeviceService } from '../infrastructure/demoDeviceService';
import DeviceWorkspace from './DeviceWorkspace.vue';

describe('Device overview', () => {
  it('shows USB information and replaces it when the selected device changes', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const wrapper = mount(DeviceWorkspace, {
      props: { device: devices[0]!, demo: true },
    });
    const details = () =>
      Object.fromEntries(
        wrapper
          .findAll('dl > div')
          .map((row) => [row.get('dt').text(), row.get('dd').text()]),
      );
    expect(details()).toEqual({
      Manufacturer: 'Google',
      'USB product': 'Pixel 9',
      'Serial number': 'DEMO-A',
      'Connection ID': 'usb:1:2:18d1:4ee7',
      'USB vendor ID': '0x18D1',
      'USB product ID': '0x4EE7',
    });
    expect(wrapper.text()).toContain('Simulated USB device');
    await wrapper.setProps({ device: devices[2]! });
    expect(details()).toEqual({
      Manufacturer: 'Unavailable',
      'USB product': 'Unavailable',
      'Serial number': 'Unavailable',
      'Connection ID': 'usb:1:4:04e8:6860',
      'USB vendor ID': '0x04E8',
      'USB product ID': '0x6860',
    });
    expect(wrapper.text()).toContain('Check USB permissions.');
    expect(wrapper.text()).not.toContain('Google');
    await wrapper.setProps({ device: null });
    expect(wrapper.find('dl').exists()).toBe(false);
    wrapper.unmount();
  });
});
