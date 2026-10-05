import { invoke } from '@tauri-apps/api/core';
import {
  ExplorerError,
  type CertificateInfo,
  type ExploredEntry,
  type KeystoreExplorerService,
  type KeystoreReport,
} from '../domain/explorer';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;
function record(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}
function certificate(value: unknown): value is CertificateInfo {
  return (
    record(value) &&
    [
      'subject',
      'issuer',
      'serial',
      'validFrom',
      'validUntil',
      'sha1',
      'sha256',
    ].every((k) => typeof value[k] === 'string') &&
    typeof value.sha1 === 'string' &&
    /^(?:[A-F0-9]{2}:){19}[A-F0-9]{2}$/.test(value.sha1) &&
    typeof value.sha256 === 'string' &&
    /^(?:[A-F0-9]{2}:){31}[A-F0-9]{2}$/.test(value.sha256)
  );
}
function entry(value: unknown): value is ExploredEntry {
  return (
    record(value) &&
    (value.alias === null || typeof value.alias === 'string') &&
    ['private_key', 'trusted_certificate', 'certificate'].includes(
      String(value.kind),
    ) &&
    ['not_checked', 'not_applicable', 'verified', 'failed'].includes(
      String(value.keyStatus),
    ) &&
    (value.kind === 'private_key'
      ? value.keyStatus !== 'not_applicable'
      : value.keyStatus === 'not_applicable') &&
    Array.isArray(value.certificates) &&
    value.certificates.every(certificate)
  );
}
function report(value: unknown): value is KeystoreReport {
  return (
    record(value) &&
    (value.format === 'jks' || value.format === 'pkcs12') &&
    (value.limitation === null || typeof value.limitation === 'string') &&
    Array.isArray(value.entries) &&
    value.entries.every(entry)
  );
}
function invalid(): never {
  throw new ExplorerError(
    'invalid_response',
    'The keystore explorer returned an invalid response.',
  );
}
export function createTauriKeystoreExplorerService(
  call: Invoke = invoke,
): KeystoreExplorerService {
  async function request(command: string, args?: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        record(error) &&
        typeof error.code === 'string' &&
        typeof error.message === 'string'
      ) {
        throw new ExplorerError(error.code, error.message);
      }
      throw new ExplorerError(
        'unavailable',
        'The keystore explorer is unavailable. Please retry.',
      );
    }
  }
  return {
    async choose() {
      const value = await request('choose_signing_keystore');
      if (value === null || (typeof value === 'string' && value.length > 0))
        return value;
      return invalid();
    },
    async inspect(input) {
      const value = await request('explore_keystore', { request: input });
      return report(value) ? value : invalid();
    },
    async copy(text) {
      await request('copy_keystore_text', { text });
    },
  };
}
