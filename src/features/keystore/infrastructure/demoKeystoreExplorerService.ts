import {
  ExplorerError,
  type KeystoreExplorerService,
} from '../domain/explorer';

export function createDemoKeystoreExplorerService(
  fail = false,
): KeystoreExplorerService {
  return {
    async choose() {
      return '/demo/upload.jks';
    },
    async copy() {},
    async inspect(request) {
      if (fail || request.password !== 'demo-password')
        throw new ExplorerError(
          'unlock_failed',
          'Could not verify the keystore password and integrity. Demo password: demo-password.',
        );
      return {
        format: 'jks',
        limitation: null,
        entries: [
          {
            alias: 'upload',
            kind: 'private_key',
            keyStatus: request.keyAlias
              ? request.keyPassword === '' ||
                request.keyPassword === 'demo-password'
                ? 'verified'
                : 'failed'
              : 'not_checked',
            certificates: [
              {
                subject: 'CN=Demo signing identity, O=Example Studio',
                issuer: 'CN=Demo signing identity, O=Example Studio',
                serial: '1234',
                validFrom: 'Oct 5 00:00:00 2026 GMT',
                validUntil: 'Oct 5 00:00:00 2056 GMT',
                sha1: Array<string>(20).fill('AA').join(':'),
                sha256: Array<string>(32).fill('BB').join(':'),
              },
            ],
          },
        ],
      };
    },
  };
}
