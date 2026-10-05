import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import SettingsWorkspace from './SettingsWorkspace.vue';
import { createDemoSettingsService } from '../infrastructure/demoSettingsService';
import { SettingsError } from '../domain/settings';

describe('Application settings', () => {
  it('saves both choices and restores the preference after navigation', async () => {
    const service = createDemoSettingsService();
    let wrapper = mount(SettingsWorkspace, { props: { service } });
    await flushPromises();
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe(
      'false',
    );
    await wrapper.get('[role="switch"]').trigger('click');
    await flushPromises();
    wrapper.unmount();
    wrapper = mount(SettingsWorkspace, { props: { service } });
    await flushPromises();
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe(
      'true',
    );
    await wrapper.get('[role="switch"]').trigger('click');
    await flushPromises();
    expect((await service.load()).crashReportingEnabled).toBe(false);
    wrapper.unmount();
  });
  it('keeps the saved choice on write failure and allows retry', async () => {
    const service = createDemoSettingsService();
    const save = vi
      .spyOn(service, 'setCrashReporting')
      .mockRejectedValueOnce(
        new SettingsError('storage_failed', 'Could not save settings.'),
      );
    const wrapper = mount(SettingsWorkspace, { props: { service } });
    await flushPromises();
    await wrapper.get('[role="switch"]').trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain('Could not save');
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe(
      'false',
    );
    await wrapper.get('[role="switch"]').trigger('click');
    await flushPromises();
    expect(save).toHaveBeenCalledTimes(2);
    expect(wrapper.get('[role="switch"]').attributes('aria-checked')).toBe(
      'true',
    );
    wrapper.unmount();
  });
  it('disables changes while loading and saving', async () => {
    const service = createDemoSettingsService();
    let finish!: (value: { crashReportingEnabled: boolean }) => void;
    service.setCrashReporting = () =>
      new Promise((resolve) => {
        finish = resolve;
      });
    const wrapper = mount(SettingsWorkspace, { props: { service } });
    expect(wrapper.get('[role="switch"]').attributes('disabled')).toBeDefined();
    await flushPromises();
    await wrapper.get('[role="switch"]').trigger('click');
    expect(wrapper.get('[role="switch"]').attributes('disabled')).toBeDefined();
    finish({ crashReportingEnabled: true });
    await flushPromises();
    expect(
      wrapper.get('[role="switch"]').attributes('disabled'),
    ).toBeUndefined();
    wrapper.unmount();
  });
  it('recovers from a load failure and handles GitHub actions and failures', async () => {
    const service = createDemoSettingsService();
    vi.spyOn(service, 'load').mockRejectedValueOnce(
      new SettingsError('storage_failed', 'Could not load settings.'),
    );
    const open = vi
      .spyOn(service, 'openProjectLink')
      .mockRejectedValueOnce(
        new SettingsError('open_failed', 'Could not open GitHub.'),
      );
    const wrapper = mount(SettingsWorkspace, { props: { service } });
    await flushPromises();
    expect(wrapper.get('[role="switch"]').attributes('disabled')).toBeDefined();
    await wrapper.get('[role="alert"] button').trigger('click');
    await flushPromises();
    const button = (label: string) =>
      wrapper.findAll('button').find((entry) => entry.text() === label)!;
    await button('Create GitHub issue').trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'Could not open GitHub',
    );
    await button('View on GitHub').trigger('click');
    await flushPromises();
    await button('View changelog').trigger('click');
    await flushPromises();
    expect(open.mock.calls).toEqual([['issue'], ['repository'], ['changelog']]);
    expect(button('Open logs folder').attributes('disabled')).toBeUndefined();
    expect(button('Check for updates').attributes('disabled')).toBeUndefined();
    wrapper.unmount();
  });
  it('opens the logs folder, blocks duplicate requests and allows retry after failure', async () => {
    const service = createDemoSettingsService();
    let reject!: (error: unknown) => void;
    const open = vi.spyOn(service, 'openLogsFolder').mockImplementationOnce(
      () =>
        new Promise((_, fail) => {
          reject = fail;
        }),
    );
    const wrapper = mount(SettingsWorkspace, {
      props: { service, demo: true },
    });
    await flushPromises();
    const button = wrapper
      .findAll('button')
      .find((entry) => entry.text() === 'Open logs folder')!;
    await button.trigger('click');
    expect(button.attributes('disabled')).toBeDefined();
    await button.trigger('click');
    expect(open).toHaveBeenCalledTimes(1);
    reject(new SettingsError('open_failed', 'Could not open logs.'));
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'Could not open logs.',
    );
    await button.trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain('simulated');
    expect(open).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });
  it('requires the native service to open logs', () => {
    const wrapper = mount(SettingsWorkspace);
    const button = wrapper
      .findAll('button')
      .find((entry) => entry.text() === 'Open logs folder')!;
    expect(button.attributes('disabled')).toBeDefined();
    wrapper.unmount();
  });
  it('blocks duplicate update checks, reports unavailable builds and permits retry', async () => {
    const service = createDemoSettingsService();
    let reject!: (error: unknown) => void;
    const check = vi.spyOn(service, 'checkForUpdates').mockImplementationOnce(
      () =>
        new Promise((_, fail) => {
          reject = fail;
        }),
    );
    const wrapper = mount(SettingsWorkspace, {
      props: { service, demo: true },
    });
    await flushPromises();
    const button = wrapper
      .findAll('button')
      .find((entry) => entry.text() === 'Check for updates')!;
    await button.trigger('click');
    expect(button.attributes('disabled')).toBeDefined();
    await button.trigger('click');
    expect(check).toHaveBeenCalledTimes(1);
    reject(
      new SettingsError(
        'updater_unavailable',
        'Updates require an installed macOS release.',
      ),
    );
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'installed macOS release',
    );
    await button.trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain('simulated');
    expect(check).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });
});
