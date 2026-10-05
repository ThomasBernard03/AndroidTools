import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import KeystoreExplorerWorkspace from './KeystoreExplorerWorkspace.vue';
import { createDemoKeystoreExplorerService } from '../infrastructure/demoKeystoreExplorerService';
import type { KeystoreReport } from '../domain/explorer';

describe('Keystore explorer', () => {
  it('opens a store, checks key credentials independently and clears stale results on edits', async () => {
    const wrapper = mount(KeystoreExplorerWorkspace, {
      props: { service: createDemoKeystoreExplorerService(), demo: true },
    });
    await wrapper.get('#explorer-path').setValue('/demo/upload.jks');
    await wrapper.get('#explorer-password').setValue('demo-password');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('store password and integrity verified');
    expect(wrapper.text()).toContain('Key password not checked');
    expect(wrapper.text()).toContain('CN=Demo signing identity');
    await wrapper.get('#explorer-alias').setValue('upload');
    await wrapper.get('#explorer-key-password').setValue('wrong');
    await wrapper.findAll('form')[1]!.trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('Key verification failed');
    await wrapper.get('#explorer-key-password').setValue('demo-password');
    expect(wrapper.text()).not.toContain('Key verification failed');
    await wrapper.findAll('form')[1]!.trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('Key unlocked — certificate matches');
    await wrapper.get('#explorer-password').setValue('wrong');
    expect(wrapper.find('article').exists()).toBe(false);
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain('Could not verify');
    expect(wrapper.text()).not.toContain(
      'store password and integrity verified',
    );
  });

  it('preserves a report when the picker is cancelled and discards late results after input changes', async () => {
    const service = createDemoKeystoreExplorerService();
    const wrapper = mount(KeystoreExplorerWorkspace, { props: { service } });
    await wrapper.get('#explorer-path').setValue('/demo/upload.jks');
    await wrapper.get('#explorer-password').setValue('demo-password');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    service.choose = vi.fn().mockResolvedValue(null);
    await wrapper
      .findAll('button')
      .find((b) => b.text() === 'Choose keystore')!
      .trigger('click');
    await flushPromises();
    expect(wrapper.find('article').exists()).toBe(true);
    let resolve!: (report: KeystoreReport) => void;
    const pending = new Promise<KeystoreReport>((r) => {
      resolve = r;
    });
    const result = await service.inspect({
      path: '',
      password: 'demo-password',
      keyAlias: null,
      keyPassword: '',
    });
    service.inspect = () => pending;
    await wrapper.get('form').trigger('submit');
    await wrapper.get('#explorer-path').setValue('/different.jks');
    resolve(result);
    await flushPromises();
    expect(wrapper.find('article').exists()).toBe(false);
  });

  it('shows empty stores and PKCS12 inventory limitations explicitly', async () => {
    const service = createDemoKeystoreExplorerService();
    service.inspect = async () => ({
      format: 'pkcs12',
      entries: [],
      limitation: 'Multi-key inventory is not supported.',
    });
    const wrapper = mount(KeystoreExplorerWorkspace, { props: { service } });
    await wrapper.get('#explorer-path').setValue('/empty.p12');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('No entries found');
    expect(wrapper.text()).toContain('Multi-key inventory is not supported');
  });
});
