import { flushPromises, mount, type VueWrapper } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import FileWorkspace from './FileWorkspace.vue';
import { createDemoFileService } from '../infrastructure/demoFileService';
import { FileError, type FileListing, type FilePreview } from '../domain/files';

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
  it('previews text as literal content and displays image decoding failures', async () => {
    const service = createDemoFileService();
    const preview = vi
      .fn()
      .mockResolvedValueOnce({
        kind: 'text',
        content: '<script>alert(1)</script>',
      })
      .mockImplementation(service.preview);
    const wrapper = mount(FileWorkspace, {
      props: { deviceId: 'a', service: { ...service, preview } },
    });
    await flushPromises();
    await button(wrapper, 'notes.txt').trigger('click');
    await flushPromises();
    expect(wrapper.get('pre').text()).toBe('<script>alert(1)</script>');
    expect(wrapper.find('script').exists()).toBe(false);
    expect(preview).toHaveBeenCalledWith('a', '/sdcard/notes.txt');
    await button(wrapper, 'Pictures').trigger('click');
    await flushPromises();
    expect(wrapper.find('pre').exists()).toBe(false);
    await wrapper
      .get('tr[aria-label="sample.png"]')
      .trigger('keydown', { key: 'Enter' });
    await flushPromises();
    expect(wrapper.get('img').attributes('src')).toContain(
      'data:image/png;base64,',
    );
    await wrapper.get('img').trigger('error');
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'could not be decoded',
    );
    wrapper.unmount();
  });
  it('discards closed and stale previews and exposes read failures', async () => {
    const old = deferred<FilePreview>();
    const preview = vi
      .fn()
      .mockReturnValueOnce(old.promise)
      .mockRejectedValue(
        new FileError('unsupported_preview', 'Unsupported preview.'),
      );
    const wrapper = mount(FileWorkspace, {
      props: {
        deviceId: 'a',
        service: { ...createDemoFileService(), preview },
      },
    });
    await flushPromises();
    await button(wrapper, 'notes.txt').trigger('click');
    expect(wrapper.text()).toContain('Loading preview');
    await button(wrapper, 'Close preview').trigger('click');
    await wrapper.setProps({ deviceId: 'b' });
    await flushPromises();
    await button(wrapper, 'notes.txt').trigger('click');
    await flushPromises();
    old.resolve({ kind: 'text', content: 'Old device content' });
    await flushPromises();
    expect(wrapper.text()).not.toContain('Old device content');
    expect(wrapper.get('[role="alert"]').text()).toBe('Unsupported preview.');
    wrapper.unmount();
  });
  it('opens folders by double-clicking metadata or empty action space, but not files', async () => {
    const service = createDemoFileService();
    const list = vi.fn(service.list);
    const wrapper = mount(FileWorkspace, {
      props: { deviceId: 'a', service: { ...service, list } },
    });
    await flushPromises();
    const folder = wrapper
      .findAll('tbody tr')
      .find((row) => row.find('button').text() === 'Download')!;
    await folder.get('td:nth-child(2)').trigger('dblclick');
    await flushPromises();
    expect(list).toHaveBeenLastCalledWith('a', '/sdcard/Download');
    await button(wrapper, 'Up').trigger('click');
    await flushPromises();
    const file = wrapper.get('tr[aria-label="notes.txt"]');
    const count = list.mock.calls.length;
    await file.get('td:nth-child(2)').trigger('dblclick');
    expect(list).toHaveBeenCalledTimes(count);
    await wrapper
      .get('tr[aria-label="Download"] td:last-child')
      .trigger('dblclick');
    await flushPromises();
    expect(list).toHaveBeenLastCalledWith('a', '/sdcard/Download');
    wrapper.unmount();
  });
  it('offers contextual transfers, rename and confirmed deletion with keyboard dismissal', async () => {
    const service = createDemoFileService();
    const transfer = vi.fn(service.transfer);
    const wrapper = mount(FileWorkspace, {
      attachTo: document.body,
      props: { deviceId: 'a', service: { ...service, transfer } },
    });
    await flushPromises();
    const menu = () => document.querySelector<HTMLElement>('[role="menu"]')!;
    const choose = async (label: string) => {
      Array.from(menu().querySelectorAll('button'))
        .find((item) => item.textContent?.trim() === label)!
        .click();
      await flushPromises();
    };
    await wrapper
      .get('tr[aria-label="notes.txt"]')
      .trigger('contextmenu', { clientX: 50, clientY: 60 });
    expect(menu().textContent).not.toContain('Open');
    await choose('Download');
    expect(transfer).toHaveBeenCalledWith(
      'a',
      '/sdcard/notes.txt',
      false,
      false,
    );
    expect(menu()).toBeNull();
    await wrapper.get('tr[aria-label="notes.txt"]').trigger('contextmenu');
    await choose('Rename');
    await wrapper.get('form input').setValue('renamed.txt');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    await wrapper
      .get('tr[aria-label="renamed.txt"]')
      .trigger('keydown', { key: 'F10', shiftKey: true });
    menu().dispatchEvent(
      new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }),
    );
    expect(document.activeElement?.textContent?.trim()).toBe('Download');
    menu().dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }),
    );
    await flushPromises();
    expect(menu()).toBeNull();
    expect(document.activeElement?.getAttribute('aria-label')).toBe(
      'renamed.txt',
    );
    await wrapper.get('tr[aria-label="renamed.txt"]').trigger('contextmenu');
    await choose('Delete');
    expect(wrapper.text()).toContain('permanently?');
    expect(wrapper.find('tr[aria-label="renamed.txt"]').exists()).toBe(true);
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.find('tr[aria-label="renamed.txt"]').exists()).toBe(false);
    wrapper.unmount();
  });
  it('closes contextual actions outside the menu and on device changes, and respects protected entries', async () => {
    const wrapper = mount(FileWorkspace, {
      attachTo: document.body,
      props: { deviceId: 'a', service: createDemoFileService() },
    });
    await flushPromises();
    await wrapper.get('tr[aria-label="Download"]').trigger('contextmenu');
    expect(document.querySelector('[role="menu"]')?.textContent).toContain(
      'Open',
    );
    document.body.dispatchEvent(new Event('pointerdown', { bubbles: true }));
    await flushPromises();
    expect(document.querySelector('[role="menu"]')).toBeNull();
    await wrapper.get('tr[aria-label="notes.txt"]').trigger('contextmenu');
    await wrapper.setProps({ deviceId: 'b' });
    expect(document.querySelector('[role="menu"]')).toBeNull();
    await flushPromises();
    await button(wrapper, 'Application data').trigger('click');
    await flushPromises();
    await wrapper.get('tbody tr').trigger('contextmenu');
    const actions = document.querySelector('[role="menu"]')!;
    expect(actions.textContent?.trim()).toBe('Open');
    wrapper.unmount();
    expect(document.querySelector('[role="menu"]')).toBeNull();
  });
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
