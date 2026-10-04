import {
  expirationDate,
  extension,
  KeystoreError,
  type KeystoreService,
} from '../domain/keystore';

/** Explicit development-only simulation: no private key or file is created. */
export function createDemoKeystoreService(fail = false): KeystoreService {
  return {
    async choosePath(format) {
      return `/demo/upload.${extension(format)}`;
    },
    async generate(request) {
      if (fail)
        throw new KeystoreError(
          'write_failed',
          'Simulated failure: the destination folder is not writable.',
        );
      return {
        path: request.path,
        format: request.format,
        alias: request.alias,
        expiresAt: expirationDate(
          request.validityYears,
          new Date('2026-10-03T12:00:00Z'),
        ),
        sha1: Array(20).fill('AA').join(':'),
        sha256: Array(32).fill('BB').join(':'),
      };
    },
    async copy(text) {
      await navigator.clipboard.writeText(text);
    },
    async reveal() {
      throw new KeystoreError(
        'demo',
        'Demo mode does not create a file to reveal.',
      );
    },
  };
}
