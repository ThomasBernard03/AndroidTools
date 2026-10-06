import { flushPromises, mount } from '@vue/test-utils';
import { defineComponent, h, KeepAlive, ref } from 'vue';
import { describe, expect, it, vi } from 'vitest';
import ApkWorkspace from './ApkWorkspace.vue';
import {
  ApkError,
  type ApkDrop,
  type ApkReport,
  type ApkService,
} from '../domain/apk';
import {
  createDemoApkService,
  demoReport,
} from '../infrastructure/demoApkService';

function fake() {
  let handler: (event: ApkDrop) => void = () => {};
  const stop = vi.fn();
  const service: ApkService = {
    ...createDemoApkService(),
    listenDrop: async (callback) => {
      handler = callback;
      return stop;
    },
  };
  return {
    service,
    stop,
    drop: (paths: string[]) => handler({ type: 'drop', paths }),
  };
}
describe('APK workspace', () => {
  it('always shows installation and explains why it is disabled until an APK and authorized device are available', async () => {
    const f = fake();
    f.service.install = vi.fn().mockResolvedValue(undefined);
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    const button = () =>
      wrapper.findAll('button').find((b) => b.text() === 'Install APK');
    expect(button()!.attributes('disabled')).toBeDefined();
    expect(wrapper.get('#apk-install-help').text()).toContain(
      'Select a device',
    );
    await button()!.trigger('click');
    expect(f.service.install).not.toHaveBeenCalled();
    await wrapper.setProps({ deviceId: 'phone', adbConnected: true });
    expect(button()!.attributes('disabled')).toBeDefined();
    expect(wrapper.get('#apk-install-help').text()).toContain('Analyze an APK');
    await wrapper.setProps({ deviceId: null, adbConnected: false });
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(button()!.attributes('disabled')).toBeDefined();
    await wrapper.setProps({ deviceId: 'phone', adbConnected: false });
    expect(button()!.attributes('disabled')).toBeDefined();
    expect(wrapper.get('#apk-install-help').text()).toContain('through ADB');
    await wrapper.setProps({ adbConnected: true });
    expect(button()!.attributes('disabled')).toBeUndefined();
    await button()!.trigger('click');
    await flushPromises();
    expect(f.service.install).toHaveBeenCalledWith(
      'phone',
      '/demo/sample.apk',
      'AB'.repeat(32),
    );
    expect(wrapper.get('[role="status"]').text()).toContain(
      'installed successfully',
    );
    await wrapper.setProps({ deviceId: null });
    expect(button()!.attributes('disabled')).toBeDefined();
    expect(wrapper.get('#apk-install-help').text()).toContain(
      'Select a device',
    );
    expect(wrapper.text()).not.toContain('installed successfully');
    wrapper.unmount();
  });
  it('prevents duplicate installs, reports failure and ignores stale installation results', async () => {
    const f = fake();
    let resolve!: () => void;
    f.service.install = vi.fn(
      () =>
        new Promise<void>((r) => {
          resolve = r;
        }),
    );
    const wrapper = mount(ApkWorkspace, {
      props: { service: f.service, deviceId: 'phone', adbConnected: true },
    });
    await wrapper.get('button').trigger('click');
    await flushPromises();
    const button = () =>
      wrapper.findAll('button').find((b) => b.text().includes('Install'))!;
    await button().trigger('click');
    expect(button().attributes('disabled')).toBeDefined();
    await button().trigger('click');
    expect(f.service.install).toHaveBeenCalledOnce();
    await wrapper.setProps({ deviceId: 'other-phone' });
    resolve();
    await flushPromises();
    expect(wrapper.text()).not.toContain('installed successfully');
    f.service.install = vi
      .fn()
      .mockRejectedValue(
        new ApkError('install_failed', 'INSTALL_FAILED_UPDATE_INCOMPATIBLE'),
      );
    await button().trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'INSTALL_FAILED_UPDATE_INCOMPATIBLE',
    );
    f.service.install = vi.fn().mockResolvedValue(undefined);
    await button().trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('installed successfully');
    wrapper.unmount();
  });
  it('shows a compact app and signature summary; cancellation preserves the report', async () => {
    const f = fake();
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('com.example.demo');
    const fields = wrapper.findAll('dl').at(0)!;
    expect(fields.text()).toContain('APK size5.00 MiB');
    expect(fields.text()).toContain('App version1.2.0 (12)');
    expect(fields.text()).toContain('DebuggableNo');
    expect(fields.text()).toContain('Minimum SDK26');
    expect(fields.text()).toContain('Maximum SDKNo maximum declared');
    expect(
      wrapper.get('[aria-labelledby="apk-signature-title"]').text(),
    ).toContain('CN=Demo signer');
    expect(wrapper.find('[aria-label="App icon unavailable"]').exists()).toBe(
      true,
    );
    for (const hidden of [
      'android.permission.INTERNET',
      'Archive contents',
      'AndroidManifest.xml',
      'Target SDK',
    ])
      expect(wrapper.text()).not.toContain(hidden);
    f.service.choosePath = async () => null;
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('com.example.demo');
    wrapper.unmount();
    expect(f.stop).toHaveBeenCalledOnce();
  });
  it('validates drops, handles failures, retries and discards stale results', async () => {
    const f = fake();
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    await flushPromises();
    f.drop(['/a.apk', '/b.apk']);
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain('single .apk');
    f.service.analyze = async () => {
      throw new ApkError('invalid_apk', 'Invalid APK');
    };
    f.drop(['/a.apk']);
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe('Invalid APK');
    let resolve!: (report: ApkReport) => void;
    f.service.analyze = () =>
      new Promise((r) => {
        resolve = r;
      });
    f.drop(['/old.apk']);
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain('Analyzing');
    f.service.analyze = async (path) => demoReport(path);
    f.drop(['/new.apk']);
    await flushPromises();
    resolve(demoReport('/old.apk'));
    await flushPromises();
    expect(wrapper.text()).toContain('new.apk');
    expect(wrapper.text()).not.toContain('old.apk');
    wrapper.unmount();
  });
  it('ignores drops while inactive and preserves results on navigation', async () => {
    const f = fake();
    const show = ref(true);
    const wrapper = mount(
      defineComponent({
        setup: () => () =>
          h(
            KeepAlive,
            {},
            {
              default: () =>
                show.value ? h(ApkWorkspace, { service: f.service }) : null,
            },
          ),
      }),
    );
    await flushPromises();
    f.drop(['/first.apk']);
    await flushPromises();
    show.value = false;
    await flushPromises();
    expect(f.stop).toHaveBeenCalledOnce();
    f.drop(['/hidden.apk']);
    show.value = true;
    await flushPromises();
    expect(wrapper.text()).toContain('first.apk');
    expect(wrapper.text()).not.toContain('hidden.apk');
    wrapper.unmount();
  });
  it('cleans up a listener that resolves after unmount', async () => {
    let resolve!: (stop: () => void) => void;
    const service = {
      ...createDemoApkService(),
      listenDrop: () =>
        new Promise<() => void>((r) => {
          resolve = r;
        }),
    };
    const wrapper = mount(ApkWorkspace, { props: { service } });
    wrapper.unmount();
    const stop = vi.fn();
    resolve(stop);
    await flushPromises();
    expect(stop).toHaveBeenCalledOnce();
  });
  it('distinguishes verified, invalid, unsupported and unsigned APKs', async () => {
    const f = fake();
    const data = demoReport();
    f.service.analyze = async () => structuredClone(data);
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    for (const [status, label] of [
      ['verified', 'Verified'],
      ['invalid', 'Invalid'],
      ['unverified', 'Not verified'],
      ['unsigned', 'Unsigned'],
    ] as const) {
      data.signature = {
        status,
        schemes: status === 'verified' ? ['v2', 'v3'] : [],
        message: `Signature result: ${status}`,
      };
      await wrapper.get('button').trigger('click');
      await flushPromises();
      const badge = wrapper.get('[aria-label="Signature verification status"]');
      expect(badge.text()).toBe(
        status === 'verified' ? 'Verified · v2, v3' : label,
      );
      expect(wrapper.text()).toContain(data.signature.message);
      expect(wrapper.text()).not.toContain(
        'Certificate inspection does not verify',
      );
    }
    wrapper.unmount();
  });
  it('shows declared maximum SDK, handles debug flags and groups identical signing certificates', async () => {
    const f = fake();
    const data = demoReport();
    const compatibility = data.sections.find(
      (s) => s.title === 'Android compatibility',
    )!;
    compatibility.items = [
      { label: 'Minimum SDK', value: null },
      { label: 'Maximum SDK', value: '34' },
    ];
    const debug = data.sections.find(
      (s) => s.title === 'Application flags (declared)',
    )!.items[0]!;
    const certificate = data.sections.find(
      (s) => s.title === 'Certificate · v2 · 1',
    )!;
    data.sections.push({ ...certificate, title: 'Certificate · v3 · 1' });
    f.service.analyze = async () => structuredClone(data);
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    for (const [flag, expected] of [
      ['true', 'Yes'],
      [null, 'No'],
      ['@bool/debug', 'Unavailable'],
    ] as const) {
      debug.value = flag;
      await wrapper.get('button').trigger('click');
      await flushPromises();
      const fields = wrapper.get('dl').text();
      expect(fields).toContain(`Debuggable${expected}`);
      expect(fields).toContain('Minimum SDK1 (Android default)');
      expect(fields).toContain('Maximum SDK34');
      expect(wrapper.findAll('details')).toHaveLength(1);
      expect(wrapper.get('summary').text()).toContain('v2 · v3');
    }
    wrapper.unmount();
  });
  it('shows a raster icon and falls back if decoding fails, then resets for the next APK', async () => {
    const f = fake();
    const data = {
      ...demoReport(),
      iconDataUrl: 'data:image/png;base64,aGVsbG8=',
    };
    f.service.analyze = async () => data;
    const wrapper = mount(ApkWorkspace, { props: { service: f.service } });
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.get('img').attributes('src')).toBe(data.iconDataUrl);
    await wrapper.get('img').trigger('error');
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.find('[aria-label="App icon unavailable"]').exists()).toBe(
      true,
    );
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(wrapper.find('img').exists()).toBe(true);
    wrapper.unmount();
  });
});
