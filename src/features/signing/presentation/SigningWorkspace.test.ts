import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import SigningWorkspace from './SigningWorkspace.vue';
import { createDemoSigningService } from '../infrastructure/demoSigningService';
import { SigningError } from '../domain/signing';

async function fill(wrapper: ReturnType<typeof mount>) {
  await wrapper.get('#signing-apk').setValue('/apps/example.apk');
  await wrapper.get('#signing-keystore').setValue('/keys/upload.jks');
  await wrapper.get('#signing-alias').setValue('upload');
  await wrapper.get('#signing-password').setValue('store-password');
}

describe('APK signing workspace', () => {
  it('validates required inputs without invoking signing', async () => {
    const service = { ...createDemoSigningService(), signAndSave: vi.fn() };
    const wrapper = mount(SigningWorkspace, { props: { service } });
    await wrapper.get('form').trigger('submit');
    expect(service.signAndSave).not.toHaveBeenCalled();
    expect(wrapper.get('[role="alert"]').text()).toContain('key alias');
    wrapper.unmount();
  });
  it('accepts typed paths, passes credentials and prevents duplicate signing', async () => {
    let finish!: (value: string | null) => void;
    const service = {
      ...createDemoSigningService(),
      signAndSave: vi.fn(
        () =>
          new Promise<string | null>((resolve) => {
            finish = resolve;
          }),
      ),
      reveal: vi.fn(),
    };
    const wrapper = mount(SigningWorkspace, { props: { service } });
    await fill(wrapper);
    await wrapper.get('#signing-key-password').setValue('separate-password');
    expect(wrapper.text()).toContain('example-signed.apk');
    await wrapper.get('form').trigger('submit');
    await wrapper.get('form').trigger('submit');
    expect(service.signAndSave).toHaveBeenCalledTimes(1);
    expect(service.signAndSave).toHaveBeenCalledWith({
      apkPath: '/apps/example.apk',
      keystorePath: '/keys/upload.jks',
      alias: 'upload',
      password: 'store-password',
      keyPassword: 'separate-password',
    });
    expect(wrapper.get('fieldset').attributes('disabled')).toBeDefined();
    expect(wrapper.text()).not.toContain('Signed APK saved');
    finish('/output/example-signed.apk');
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain(
      '/output/example-signed.apk',
    );
    await wrapper.get('[role="status"] button').trigger('click');
    expect(service.reveal).toHaveBeenCalledWith('/output/example-signed.apk');
    wrapper.unmount();
  });
  it('reports cancelled saving separately and allows retry after a signing error', async () => {
    const signAndSave = vi
      .fn()
      .mockResolvedValueOnce(null)
      .mockRejectedValueOnce(
        new SigningError('invalid_keystore', 'Wrong keystore password.'),
      )
      .mockResolvedValueOnce('/output/example-signed.apk');
    const wrapper = mount(SigningWorkspace, {
      props: { service: { ...createDemoSigningService(), signAndSave } },
    });
    await fill(wrapper);
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.get('[role="status"]').text()).toContain('Save cancelled');
    expect(wrapper.text()).not.toContain('Signed APK saved');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe(
      'Wrong keystore password.',
    );
    expect(wrapper.text()).not.toContain('Save cancelled');
    await wrapper.get('#signing-password').setValue('corrected');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('Signed APK saved');
    wrapper.unmount();
  });
  it('keeps paths when pickers are cancelled and exposes selection failures', async () => {
    const chooseApk = vi
      .fn()
      .mockResolvedValueOnce('/chosen/app.apk')
      .mockResolvedValueOnce(null)
      .mockRejectedValueOnce(
        new SigningError('native_operation_failed', 'Could not open dialog.'),
      );
    const wrapper = mount(SigningWorkspace, {
      props: { service: { ...createDemoSigningService(), chooseApk } },
    });
    const button = wrapper
      .findAll('button')
      .find((b) => b.text() === 'Choose APK')!;
    await button.trigger('click');
    await flushPromises();
    expect(wrapper.get<HTMLInputElement>('#signing-apk').element.value).toBe(
      '/chosen/app.apk',
    );
    await button.trigger('click');
    await flushPromises();
    expect(wrapper.get<HTMLInputElement>('#signing-apk').element.value).toBe(
      '/chosen/app.apk',
    );
    await button.trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe('Could not open dialog.');
    wrapper.unmount();
  });
  it('requires the native runtime and clearly labels explicit simulations', () => {
    const unavailable = mount(SigningWorkspace);
    expect(unavailable.get('[role="alert"]').text()).toContain(
      'desktop application',
    );
    expect(unavailable.get('fieldset').attributes('disabled')).toBeDefined();
    unavailable.unmount();
    const demo = mount(SigningWorkspace, {
      props: { service: createDemoSigningService(), demo: true },
    });
    expect(demo.get('[role="note"]').text()).toContain('No file is created');
    demo.unmount();
  });
});
