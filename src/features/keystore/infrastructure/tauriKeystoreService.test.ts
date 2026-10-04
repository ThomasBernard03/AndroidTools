import { describe, expect, it, vi } from 'vitest';
import { createTauriKeystoreService } from './tauriKeystoreService';
import { createDemoKeystoreService } from './demoKeystoreService';
import {
  expirationDate,
  type GenerateRequest,
  validateRequest,
} from '../domain/keystore';

const input: GenerateRequest = {
  path: '/tmp/upload.jks',
  format: 'JKS',
  alias: 'upload',
  password: 'store-password',
  keyPassword: 'store-password',
  validityYears: 30,
  commonName: 'Signing',
  organization: '',
  organizationalUnit: '',
  locality: '',
  state: '',
  country: '',
};
describe('Keystore service and validation', () => {
  it('validates the native result and forwards the creation contract', async () => {
    const result = await createDemoKeystoreService().generate(input);
    const call = vi.fn().mockResolvedValue(result);
    const service = createTauriKeystoreService(call);
    expect(await service.generate(input)).toEqual(result);
    expect(call).toHaveBeenCalledWith('generate_keystore', { request: input });
    for (const invalid of [
      null,
      {},
      { ...result, sha256: 'invalid' },
      { ...result, path: '/wrong.jks' },
      { ...result, format: 'PKCS12' },
    ]) {
      call.mockResolvedValueOnce(invalid);
      await expect(service.generate(input)).rejects.toMatchObject({
        code: 'invalid_response',
      });
    }
  });
  it('handles cancellation and malformed paths, and translates structured errors', async () => {
    const call = vi
      .fn()
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(42)
      .mockRejectedValueOnce({
        code: 'invalid_input',
        message: 'Invalid alias.',
        field: 'alias',
      })
      .mockRejectedValueOnce('unknown');
    const service = createTauriKeystoreService(call);
    expect(await service.choosePath('JKS')).toBeNull();
    await expect(service.choosePath('JKS')).rejects.toMatchObject({
      code: 'invalid_response',
    });
    await expect(service.generate(input)).rejects.toMatchObject({
      code: 'invalid_input',
      field: 'alias',
      message: 'Invalid alias.',
    });
    await expect(service.copy('secret')).rejects.toMatchObject({
      code: 'unavailable',
    });
  });
  it('validates compatibility constraints without trimming passwords', () => {
    expect(validateRequest(input)).toEqual({});
    expect(validateRequest({ ...input, keyPassword: '' })).toEqual({});
    expect(
      validateRequest({ ...input, password: '', keyPassword: '' }).password,
    ).toBeDefined();
    expect(
      validateRequest({ ...input, keyPassword: '   ' }).keyPassword,
    ).toBeDefined();
    expect(
      validateRequest({
        ...input,
        password: ' leading and trailing ',
        keyPassword: ' leading and trailing ',
      }),
    ).toEqual({});
    expect(
      validateRequest({
        ...input,
        password: 'éèàpassword',
        commonName: '',
        alias: 'UPPER',
        validityYears: 1.5,
        country: 'FRA',
      }),
    ).toMatchObject({
      password: expect.any(String),
      commonName: expect.any(String),
      alias: expect.any(String),
      validityYears: expect.any(String),
      country: expect.any(String),
    });
    expect(
      validateRequest({ ...input, path: 'relative.jks' }).path,
    ).toBeDefined();
    expect(expirationDate(1, new Date('2024-02-29T12:00:00Z'))).toBe(
      '2025-02-28',
    );
  });
  it('keeps demo failures explicit', async () => {
    await expect(
      createDemoKeystoreService(true).generate(input),
    ).rejects.toMatchObject({ code: 'write_failed' });
  });
});
