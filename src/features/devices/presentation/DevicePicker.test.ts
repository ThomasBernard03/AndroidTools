import { flushPromises, mount } from '@vue/test-utils';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { DeviceDiscoveryError, type DeviceSummary } from '../domain/devices';
import { createDemoDeviceService } from '../infrastructure/demoDeviceService';
import DevicePicker from './DevicePicker.vue';

const wrappers: ReturnType<typeof mount>[] = [];
afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
});

function render(list = createDemoDeviceService('devices').list) {
  const wrapper = mount(DevicePicker, { props: { service: { list } } });
  wrappers.push(wrapper);
  return wrapper;
}

describe('Device selection', () => {
  it('shows loading and disables controls until discovery finishes', async () => {
    let resolve!: (devices: DeviceSummary[]) => void;
    const wrapper = render(
      () =>
        new Promise((done) => {
          resolve = done;
        }),
    );
    await flushPromises();
    expect(wrapper.get('select').attributes('disabled')).toBeDefined();
    expect(wrapper.get('button').attributes('disabled')).toBeDefined();
    expect(wrapper.get('[role="status"]').text()).toContain('Looking for');
    resolve([]);
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain(
      'No Android devices found',
    );
    expect(wrapper.get('button').attributes('disabled')).toBeUndefined();
  });

  it('selects the first detected device and allows choosing another identical model', async () => {
    const wrapper = render();
    await flushPromises();
    expect(wrapper.findAll('option').map((option) => option.text())).toEqual(
      expect.arrayContaining([
        expect.stringContaining('DEMO-A'),
        expect.stringContaining('DEMO-B'),
        expect.stringContaining('Limited metadata'),
      ]),
    );
    expect(wrapper.get('select').element.value).toBe('usb:1:2:18d1:4ee7');
    await wrapper.get('select').setValue('usb:1:3:18d1:4ee7');
    expect(wrapper.get('h3').text()).toBe('Selected device');
    expect(wrapper.text()).toContain('ADB authorization has not been checked');
    expect(wrapper.get('select').element.value).toBe('usb:1:3:18d1:4ee7');
  });

  it('keeps selection when still present and clears it after disconnection', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const list = vi
      .fn()
      .mockResolvedValueOnce(devices)
      .mockResolvedValueOnce([...devices].reverse())
      .mockResolvedValueOnce([]);
    const wrapper = render(list);
    await flushPromises();
    await wrapper.get('select').setValue(devices[1]!.id);
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('select').element.value).toBe(devices[1]!.id);
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('select').element.value).toBe('');
    expect(wrapper.find('h3').exists()).toBe(false);
  });

  it('reports failure, clears stale selection and allows retry', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const list = vi
      .fn()
      .mockResolvedValueOnce(devices)
      .mockRejectedValueOnce(
        new DeviceDiscoveryError('usb_unavailable', 'USB access denied'),
      )
      .mockResolvedValueOnce(devices);
    const wrapper = render(list);
    await flushPromises();
    await wrapper.get('select').setValue(devices[0]!.id);
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe('USB access denied');
    expect(wrapper.find('h3').exists()).toBe(false);
    expect(wrapper.findAll('option')).toHaveLength(1);
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.findAll('option')).toHaveLength(4);
    expect(wrapper.get('select').element.value).toBe(devices[0]!.id);
  });

  it('selects a newly discovered device and falls back when the selected device disappears', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const list = vi
      .fn()
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([devices[1]])
      .mockResolvedValueOnce([devices[0], devices[2]]);
    const wrapper = render(list);
    await flushPromises();
    expect(wrapper.get('select').element.value).toBe('');
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('select').element.value).toBe(devices[1]!.id);
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('select').element.value).toBe(devices[0]!.id);
  });

  it('retains selectable devices with missing metadata and explains the limitation', async () => {
    const wrapper = render();
    await flushPromises();
    await wrapper.get('select').setValue('usb:1:4:04e8:6860');
    expect(wrapper.text()).toContain('Serial unavailable');
    expect(wrapper.text()).toContain('Check USB permissions.');
  });
});
