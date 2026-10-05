import {
  SigningError,
  signedFilename,
  type SigningService,
} from '../domain/signing';

export function createDemoSigningService(fail = false): SigningService {
  return {
    async chooseApk() {
      return '/demo/example.apk';
    },
    async chooseKeystore() {
      return '/demo/upload.jks';
    },
    async signAndSave(request) {
      if (fail)
        throw new SigningError(
          'invalid_keystore',
          'Simulated failure: could not unlock the signing key. Check the alias and passwords.',
        );
      return `/demo/${signedFilename(request.apkPath)}`;
    },
    async copy() {},
    async reveal() {},
  };
}
