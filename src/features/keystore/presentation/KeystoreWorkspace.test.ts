import { flushPromises, mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import KeystoreWorkspace from './KeystoreWorkspace.vue';
import { createDemoKeystoreService } from '../infrastructure/demoKeystoreService';
import { KeystoreError, type GeneratedKeystore } from '../domain/keystore';

function setup() {
  const service = createDemoKeystoreService();
  const generate = vi.spyOn(service, 'generate');
  const copy = vi.spyOn(service, 'copy').mockResolvedValue();
  const reveal = vi.spyOn(service, 'reveal').mockResolvedValue();
  const wrapper = mount(KeystoreWorkspace, { props: { service } });
  return { wrapper, service, generate, copy, reveal };
}
async function fill(wrapper: ReturnType<typeof setup>['wrapper']) {
  await wrapper.get('#keystore-path').setValue('/tmp/upload.jks');
  await wrapper.get('#store-password').setValue('store-password');
  await wrapper.get('#store-confirmation').setValue('store-password');
  await wrapper.get('#identity-commonName').setValue('Example Signing');
}

describe('Generate keystore workspace', () => {
  it('generates with the shared password, displays the result and supports copying and revealing', async () => {
    const { wrapper, generate, copy, reveal } = setup();
    await fill(wrapper);
    await wrapper.get('#identity-country').setValue('fr');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(generate).toHaveBeenCalledWith(
      expect.objectContaining({
        password: 'store-password',
        keyPassword: 'store-password',
        country: 'FR',
        validityYears: 30,
        alias: 'upload',
      }),
    );
    expect(wrapper.text()).toContain('Keystore generated successfully');
    await wrapper.get('[aria-label="Copy SHA-256"]').trigger('click');
    await flushPromises();
    expect(copy).toHaveBeenCalledWith(Array(32).fill('BB').join(':'));
    await wrapper
      .findAll('button')
      .find((b) => b.text() === 'Show in folder')!
      .trigger('click');
    expect(reveal).toHaveBeenCalledWith('/tmp/upload.jks');
    await wrapper.get('#key-alias').setValue('changed');
    expect(wrapper.text()).not.toContain('Keystore generated successfully');
    wrapper.unmount();
  });

  it('shows, hides, copies and securely generates passwords with matching confirmations', async () => {
    const { wrapper, copy } = setup();
    await wrapper
      .get('[aria-label="Generate keystore password"]')
      .trigger('click');
    const password = wrapper.get<HTMLInputElement>('#store-password');
    expect(password.element.value).toMatch(/^[A-Za-z0-9_-]{24}$/);
    expect(
      wrapper.get<HTMLInputElement>('#store-confirmation').element.value,
    ).toBe(password.element.value);
    expect(password.attributes('type')).toBe('password');
    await wrapper.get('[aria-label="Show keystore password"]').trigger('click');
    expect(password.attributes('type')).toBe('text');
    await wrapper.get('[aria-label="Hide keystore password"]').trigger('click');
    expect(password.attributes('type')).toBe('password');
    await wrapper.get('[aria-label="Copy keystore password"]').trigger('click');
    await flushPromises();
    expect(copy).toHaveBeenCalledWith(password.element.value);
    expect(wrapper.text()).toContain('Copied');
    copy.mockRejectedValueOnce(new Error('clipboard failed'));
    await wrapper.get('[aria-label="Copy confirm password"]').trigger('click');
    await flushPromises();
    expect(wrapper.text()).toContain('Could not copy. Please retry.');
    await wrapper.get('input[type="checkbox"]').setValue(false);
    await wrapper.get('[aria-label="Generate key password"]').trigger('click');
    expect(
      wrapper.get<HTMLInputElement>('#key-confirmation').element.value,
    ).toBe(wrapper.get<HTMLInputElement>('#key-password').element.value);
    expect(
      wrapper.find('[aria-label="Generate confirm key password"]').exists(),
    ).toBe(false);
    wrapper.unmount();
  });

  it('validates confirmations and a separate JKS key password before submitting', async () => {
    const { wrapper, generate } = setup();
    await fill(wrapper);
    await wrapper.get('#store-confirmation').setValue('different');
    await wrapper.get('input[type="checkbox"]').setValue(false);
    await wrapper.get('#key-password').setValue('short');
    await wrapper.get('form').trigger('submit');
    expect(generate).not.toHaveBeenCalled();
    expect(wrapper.text()).toContain('Passwords do not match.');
    expect(wrapper.get('#key-password').attributes('aria-invalid')).toBe(
      'true',
    );
    await wrapper.get('#store-confirmation').setValue('store-password');
    await wrapper.get('#key-password').setValue('key-password');
    await wrapper.get('#key-confirmation').setValue('key-password');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(generate).toHaveBeenCalledWith(
      expect.objectContaining({
        password: 'store-password',
        keyPassword: 'key-password',
      }),
    );
    wrapper.unmount();
  });

  it('switches PKCS12 to a shared password and updates the file extension', async () => {
    const { wrapper, generate } = setup();
    await fill(wrapper);
    await wrapper.get('input[type="checkbox"]').setValue(false);
    await wrapper.get('#keystore-format').trigger('click');
    await wrapper
      .get('[role="option"][id="keystore-format-option-1"]')
      .trigger('click');
    expect(wrapper.get<HTMLInputElement>('#keystore-path').element.value).toBe(
      '/tmp/upload.p12',
    );
    expect(wrapper.find('#key-password').exists()).toBe(false);
    expect(
      wrapper.get<HTMLInputElement>('input[type="checkbox"]').element.disabled,
    ).toBe(true);
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(generate).toHaveBeenCalledWith(
      expect.objectContaining({
        format: 'PKCS12',
        keyPassword: 'store-password',
      }),
    );
    wrapper.unmount();
  });

  it('reuses the store password when the optional key password is cleared', async () => {
    const { wrapper, generate } = setup();
    await fill(wrapper);
    await wrapper.get('input[type="checkbox"]').setValue(false);
    await wrapper.get('#key-password').setValue('separate-password');
    await wrapper.get('#key-confirmation').setValue('separate-password');
    await wrapper.get('#key-password').setValue('');
    expect(wrapper.get('#key-password-description').text()).toContain(
      'Leave empty to use the keystore password',
    );
    expect(
      wrapper.get<HTMLInputElement>('#key-confirmation').element.value,
    ).toBe('');
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(generate).toHaveBeenCalledWith(
      expect.objectContaining({
        password: 'store-password',
        keyPassword: 'store-password',
      }),
    );
    wrapper.unmount();
  });

  it('preserves the path when browsing is cancelled and handles native errors and extensionless paths', async () => {
    const { wrapper, service } = setup();
    await fill(wrapper);
    const choose = vi
      .spyOn(service, 'choosePath')
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce('/tmp/new-store')
      .mockRejectedValueOnce(
        new KeystoreError('native_operation_failed', 'Dialog unavailable.'),
      );
    const browse = wrapper
      .findAll('button')
      .find((b) => b.text() === 'Browse…')!;
    await browse.trigger('click');
    await flushPromises();
    expect(wrapper.get<HTMLInputElement>('#keystore-path').element.value).toBe(
      '/tmp/upload.jks',
    );
    await browse.trigger('click');
    await flushPromises();
    expect(wrapper.get<HTMLInputElement>('#keystore-path').element.value).toBe(
      '/tmp/new-store.jks',
    );
    await browse.trigger('click');
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe('Dialog unavailable.');
    expect(choose).toHaveBeenCalledWith('JKS');
    wrapper.unmount();
  });

  it('blocks duplicate submissions and permits retry after a failed generation', async () => {
    const { wrapper, generate } = setup();
    await fill(wrapper);
    let reject!: (error: Error) => void;
    generate.mockImplementationOnce(
      () =>
        new Promise<GeneratedKeystore>((_, fail) => {
          reject = fail;
        }),
    );
    await wrapper.get('form').trigger('submit');
    await wrapper.get('form').trigger('submit');
    expect(generate).toHaveBeenCalledTimes(1);
    expect(wrapper.get('fieldset').attributes('disabled')).toBeDefined();
    expect(wrapper.text()).toContain('Generating keystore…');
    reject(new KeystoreError('already_exists', 'A file already exists.'));
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toBe('A file already exists.');
    expect(wrapper.get<HTMLInputElement>('#store-password').element.value).toBe(
      'store-password',
    );
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.text()).toContain('Keystore generated successfully');
    wrapper.unmount();
  });

  it('makes browser-only and simulated operation explicit', async () => {
    const unavailable = mount(KeystoreWorkspace);
    expect(unavailable.get('[role="alert"]').text()).toContain(
      'requires the desktop application',
    );
    expect(unavailable.get('fieldset').attributes('disabled')).toBeDefined();
    unavailable.unmount();
    const { wrapper } = setup();
    await wrapper.setProps({ demo: true });
    await fill(wrapper);
    await wrapper.get('form').trigger('submit');
    await flushPromises();
    expect(wrapper.get('[role="note"]').text()).toContain(
      'No key or file is created',
    );
    expect(wrapper.text()).toContain('Simulated keystore generated');
    wrapper.unmount();
  });
});
