import { describe, expect, it, vi } from 'vitest';
import { createTauriSigningService } from './tauriSigningService';
import { createDemoSigningService } from './demoSigningService';
import { SigningError, signedFilename } from '../domain/signing';

const input = {
  apkPath: '/apps/my.app.apk',
  keystorePath: '/keys/upload.jks',
  alias: 'upload',
  password: 'store password',
  keyPassword: 'key password',
};

describe('APK signing service', () => {
  it('passes credentials to the native workflow and accepts save cancellation', async () => {
    const call = vi
      .fn()
      .mockResolvedValueOnce('/output/my.app-signed.apk')
      .mockResolvedValueOnce(null);
    const service = createTauriSigningService(call);
    expect(await service.signAndSave(input)).toBe('/output/my.app-signed.apk');
    expect(call).toHaveBeenCalledWith('sign_apk', { request: input });
    expect(await service.signAndSave(input)).toBeNull();
  });
  it('validates path responses for signing and both pickers', async () => {
    for (const value of [undefined, '', 7, {}, { path: '/output.apk' }]) {
      const service = createTauriSigningService(
        vi.fn().mockResolvedValue(value),
      );
      await expect(service.signAndSave(input)).rejects.toMatchObject({
        code: 'invalid_response',
      });
      await expect(service.chooseApk()).rejects.toMatchObject({
        code: 'invalid_response',
      });
      await expect(service.chooseKeystore()).rejects.toMatchObject({
        code: 'invalid_response',
      });
    }
  });
  it('preserves structured errors and hides unexpected native failures', async () => {
    const error = {
      code: 'invalid_keystore',
      message: 'Check the alias and passwords.',
    };
    await expect(
      createTauriSigningService(vi.fn().mockRejectedValue(error)).signAndSave(
        input,
      ),
    ).rejects.toMatchObject(error);
    await expect(
      createTauriSigningService(
        vi.fn().mockRejectedValue('internal details'),
      ).signAndSave(input),
    ).rejects.toMatchObject({ code: 'unavailable' });
  });
  it('uses scoped commands for file selection and result actions', async () => {
    const call = vi.fn().mockResolvedValue(null);
    const service = createTauriSigningService(call);
    expect(await service.chooseApk()).toBeNull();
    expect(await service.chooseKeystore()).toBeNull();
    await service.copy('value');
    await service.reveal('/output.apk');
    expect(call.mock.calls).toEqual([
      ['choose_apk_path', undefined],
      ['choose_signing_keystore', undefined],
      ['copy_keystore_text', { text: 'value' }],
      ['reveal_keystore', { path: '/output.apk' }],
    ]);
  });
  it('keeps demo success and failure explicit and handles platform filenames', async () => {
    expect(signedFilename('C:\\apps\\my.app.APK')).toBe('my.app-signed.apk');
    expect(signedFilename('/apps/example.apk')).toBe('example-signed.apk');
    expect(await createDemoSigningService().signAndSave(input)).toBe(
      '/demo/my.app-signed.apk',
    );
    await expect(
      createDemoSigningService(true).signAndSave(input),
    ).rejects.toBeInstanceOf(SigningError);
  });
});
