import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import WindowControls from './WindowControls.vue';
import type { WindowControlsService } from '../../infrastructure/windowControls';

function createFakeService(maximized = false) {
  const calls: string[] = [];
  let current = maximized;
  let resizeHandler: (() => void) | undefined;
  const unlisten = vi.fn();
  const service: WindowControlsService = {
    async minimize() {
      calls.push('minimize');
    },
    async toggleMaximize() {
      calls.push('toggleMaximize');
      current = !current;
    },
    async close() {
      calls.push('close');
    },
    async isMaximized() {
      return current;
    },
    async onResized(handler) {
      resizeHandler = handler;
      return unlisten;
    },
  };
  return {
    calls,
    unlisten,
    notifyResized() {
      resizeHandler?.();
    },
    service,
  };
}

describe('WindowControls', () => {
  it('drives minimize, maximize and close through the injected service', async () => {
    const fake = createFakeService();
    const wrapper = mount(WindowControls, {
      props: { service: fake.service },
    });
    await flushPromises();
    const buttons = wrapper.findAll('button');
    expect(buttons.map((button) => button.attributes('aria-label'))).toEqual([
      'Minimize',
      'Maximize',
      'Close',
    ]);
    await buttons[0]!.trigger('click');
    await buttons[1]!.trigger('click');
    await buttons[2]!.trigger('click');
    await flushPromises();
    expect(fake.calls).toEqual(['minimize', 'toggleMaximize', 'close']);
    expect(buttons[1]!.attributes('aria-label')).toBe('Restore');
    wrapper.unmount();
  });

  it('shows restore when the window starts maximized', async () => {
    const fake = createFakeService(true);
    const wrapper = mount(WindowControls, {
      props: { service: fake.service },
    });
    try {
      await flushPromises();
      expect(wrapper.findAll('button')[1]!.attributes('aria-label')).toBe(
        'Restore',
      );
    } finally {
      wrapper.unmount();
    }
  });

  it('syncs the maximize label and unlistens on unmount', async () => {
    const fake = createFakeService();
    const wrapper = mount(WindowControls, {
      props: { service: fake.service },
    });
    try {
      await flushPromises();
      expect(wrapper.findAll('button')[1]!.attributes('aria-label')).toBe(
        'Maximize',
      );
      await fake.service.toggleMaximize();
      fake.notifyResized();
      await flushPromises();
      expect(wrapper.findAll('button')[1]!.attributes('aria-label')).toBe(
        'Restore',
      );
      expect(fake.unlisten).not.toHaveBeenCalled();
    } finally {
      wrapper.unmount();
    }
    expect(fake.unlisten).toHaveBeenCalledTimes(1);
  });
});
