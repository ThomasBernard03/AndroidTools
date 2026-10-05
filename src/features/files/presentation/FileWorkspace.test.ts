import { flushPromises, mount, type VueWrapper } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import FileWorkspace from './FileWorkspace.vue';
import { createDemoFileService } from '../infrastructure/demoFileService';
import { FileError, type FileListing } from '../domain/files';

function button(wrapper: VueWrapper, label: string) {
  return wrapper.findAll('button').find((b) => b.text() === label)!;
}
function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((r) => {
    resolve = r;
  });
  return { promise, resolve };
}

describe('File explorer', () => {
  it('navigates all locations and reports private access failures with retry', async () => {
    const wrapper = mount(FileWorkspace, {
      props: { deviceId: 'a', service: createDemoFileService() },
    });
    await flushPromises();
    expect(wrapper.text()).toContain('notes.txt');
    await button(wrapper, 'Application data').trigger('click');
    await flushPromises();
    await button(wrapper, 'com.example.production').trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain('access denied');
    expect(button(wrapper, 'Retry').exists()).toBe(true);
    await button(wrapper, 'Android root').trigger('click');
    await flushPromises();
    expect(button(wrapper, 'system').exists()).toBe(true);
    wrapper.unmount();
  });
  it('renames, creates, uploads and confirms deletion through the service', async () => {
    const wrapper = mount(FileWorkspace, {
      props: { deviceId: 'a', service: createDemoFileService() },
    });
    await flushPromises();
    await wrapper.get('[aria-label="Rename notes.txt"]').trigger('click');
    await wrapper.get('form input').setValue('renamed.txt');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('renamed.txt');
    await wrapper.get('[aria-label="Delete renamed.txt"]').trigger('click');
    expect(wrapper.text()).toContain('cannot be undone');
    await button(wrapper, 'Cancel').trigger('click');
    expect(wrapper.find('[aria-label="Delete renamed.txt"]').exists()).toBe(
      true,
    );
    await wrapper.get('[aria-label="Delete renamed.txt"]').trigger('click');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.text()).not.toContain('renamed.txt');
    await button(wrapper, 'New folder').trigger('click');
    await wrapper.get('form input').setValue('New directory');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    await button(wrapper, 'Upload folder').trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('Uploaded folder');
    await button(wrapper, 'New directory').trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('This folder is empty');
    wrapper.unmount();
  });
  it('discards old directory results after switching devices', async () => {
    const old = deferred<FileListing>();
    const service = createDemoFileService();
    const list = vi
      .fn()
      .mockImplementationOnce(() => old.promise)
      .mockImplementation(service.list);
    const wrapper = mount(FileWorkspace, {
      props: { deviceId: 'a', service: { ...service, list } },
    });
    await wrapper.setProps({ deviceId: 'b' });
    await flushPromises();
    old.resolve({ path: '/sdcard', entries: [] });
    await flushPromises();
    expect(wrapper.text()).toContain('notes.txt');
    expect(wrapper.text()).not.toContain('This folder is empty');
    wrapper.unmount();
  });
  it('locks actions during a transfer and ignores its result after device changes', async () => {
    const transfer = deferred<boolean>();
    const service = {
      ...createDemoFileService(),
      transfer: vi.fn(() => transfer.promise),
    };
    const wrapper = mount(FileWorkspace, { props: { deviceId: 'a', service } });
    await flushPromises();
    await button(wrapper, 'Upload file').trigger('click');
    expect(
      button(wrapper, 'Upload folder').attributes('disabled'),
    ).toBeDefined();
    await wrapper.setProps({ deviceId: 'b' });
    transfer.resolve(true);
    await flushPromises();
    expect(service.transfer).toHaveBeenCalledWith('a', '/sdcard', true, false);
    expect(wrapper.text()).not.toContain('Upload completed');
    expect(wrapper.text()).toContain('notes.txt');
    wrapper.unmount();
  });
  it('treats picker cancellation as cancellation and explains partial failures', async () => {
    const transfer = vi
      .fn()
      .mockResolvedValueOnce(false)
      .mockRejectedValueOnce(
        new FileError('disconnected', 'Connection lost.', true),
      );
    const wrapper = mount(FileWorkspace, {
      props: {
        deviceId: 'a',
        service: { ...createDemoFileService(), transfer },
      },
    });
    await flushPromises();
    await wrapper.get('[aria-label="Download notes.txt"]').trigger('click');
    await flushPromises();
    expect(wrapper.text()).not.toContain('Download completed');
    await button(wrapper, 'Upload file').trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'Some changes may already have been applied',
    );
    await wrapper.setProps({ deviceId: null });
    expect(wrapper.text()).not.toContain('notes.txt');
    expect(wrapper.text()).toContain('Select a device');
    wrapper.unmount();
  });
});
