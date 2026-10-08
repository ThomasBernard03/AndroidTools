import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import { AdbError } from '../domain/adb';
import DevicePreview from './DevicePreview.vue';

describe('Device screen preview', () => {
  const props = {
    deviceId: 'phone-a',
    deviceName: 'Pixel',
    connected: true,
    demo: false,
  };

  it('saves the displayed image without recapturing, handles cancellation and preserves the preview on failure', async () => {
    const image = 'data:image/png;base64,displayed';
    const capture = vi.fn().mockResolvedValue(image);
    let finish!: (saved: boolean) => void;
    const save = vi
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise<boolean>((resolve) => {
            finish = resolve;
          }),
      )
      .mockResolvedValueOnce(false)
      .mockRejectedValueOnce(
        new AdbError('save_failed', 'Destination is not writable.'),
      );
    const wrapper = mount(DevicePreview, {
      props: { ...props, service: { capture, save } },
    });
    const button = () => wrapper.findAll('button')[1]!;
    expect(button().attributes('disabled')).toBeDefined();
    await flushPromises();
    await button().trigger('click');
    expect(save).toHaveBeenCalledWith(image, 'phone-a');
    expect(button().attributes('disabled')).toBeDefined();
    finish(true);
    await flushPromises();
    expect(wrapper.text()).toContain('Preview saved.');
    await button().trigger('click');
    await flushPromises();
    expect(wrapper.text()).not.toContain('Preview saved.');
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    await button().trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe(
      'Destination is not writable.',
    );
    expect(wrapper.get('img').attributes('src')).toBe(image);
    expect(capture).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });

  it('does not show an obsolete save result on another device', async () => {
    let finish!: (saved: boolean) => void;
    const service = {
      capture: vi.fn().mockResolvedValue('data:image/png;base64,preview'),
      save: vi.fn().mockImplementation(
        () =>
          new Promise<boolean>((resolve) => {
            finish = resolve;
          }),
      ),
    };
    const wrapper = mount(DevicePreview, { props: { ...props, service } });
    await flushPromises();
    await wrapper.findAll('button')[1]!.trigger('click');
    await wrapper.setProps({ deviceId: 'phone-b' });
    finish(true);
    await flushPromises();
    expect(wrapper.text()).not.toContain('Preview saved.');
    wrapper.unmount();
  });

  it('waits for authorization, captures automatically and supports manual refresh and retry', async () => {
    const capture = vi.fn().mockResolvedValue('data:image/png;base64,first');
    const wrapper = mount(DevicePreview, {
      props: {
        ...props,
        connected: false,
        service: { capture, save: vi.fn() },
      },
    });
    expect(capture).not.toHaveBeenCalled();
    expect(wrapper.get('button').attributes('disabled')).toBeDefined();
    await wrapper.setProps({ connected: true });
    await flushPromises();
    expect(capture).toHaveBeenCalledWith('phone-a');
    expect(wrapper.get('img').attributes('alt')).toBe(
      'Screen capture of Pixel',
    );
    capture.mockRejectedValueOnce(
      new AdbError('read_failed', 'Unlock the phone and retry.'),
    );
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.get('[role="alert"]').text()).toBe(
      'Unlock the phone and retry.',
    );
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.find('img').exists()).toBe(true);
    await wrapper.setProps({ connected: false });
    expect(wrapper.find('img').exists()).toBe(false);
    wrapper.unmount();
  });

  it('discards captures from an obsolete device and after unmount', async () => {
    let finish!: (image: string) => void;
    const capture = vi
      .fn()
      .mockImplementationOnce(
        () =>
          new Promise<string>((resolve) => {
            finish = resolve;
          }),
      )
      .mockResolvedValue('data:image/png;base64,second');
    const wrapper = mount(DevicePreview, {
      props: { ...props, service: { capture, save: vi.fn() } },
    });
    expect(wrapper.text()).toContain('Capturing screen');
    await wrapper.setProps({ deviceId: 'phone-b' });
    await flushPromises();
    finish('data:image/png;base64,obsolete');
    await flushPromises();
    expect(wrapper.get('img').attributes('src')).toBe(
      'data:image/png;base64,second',
    );
    capture.mockImplementationOnce(
      () =>
        new Promise<string>((resolve) => {
          finish = resolve;
        }),
    );
    await wrapper.get('button').trigger('click');
    wrapper.unmount();
    finish('data:image/png;base64,unmounted');
    await flushPromises();
  });
});
