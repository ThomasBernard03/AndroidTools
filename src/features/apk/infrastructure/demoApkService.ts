import { ApkError, type ApkReport, type ApkService } from '../domain/apk';

export function demoReport(path = '/demo/sample.apk'): ApkReport {
  return {
    path,
    size: 5242880,
    iconDataUrl: null,
    signature: {
      status: 'verified',
      schemes: ['v2'],
      message:
        'Simulated verification result. No real APK signature was checked.',
    },
    sha256: 'AB'.repeat(32),
    sections: [
      {
        title: 'Application',
        items: [
          { label: 'Package name', value: 'com.example.demo' },
          { label: 'Application label', value: 'Demo application' },
          { label: 'Version name', value: '1.2.0' },
          { label: 'Version code', value: '12' },
        ],
      },
      {
        title: 'Android compatibility',
        items: [
          { label: 'Minimum SDK', value: '26' },
          { label: 'Target SDK (declared)', value: '35' },
          { label: 'Maximum SDK', value: null },
        ],
      },
      {
        title: 'Application flags (declared)',
        items: [{ label: 'Debuggable', value: 'false' }],
      },
      {
        title: 'Certificate · v2 · 1',
        items: [
          { label: 'Subject', value: 'CN=Demo signer' },
          { label: 'Issuer', value: 'CN=Demo signer' },
          { label: 'Serial number', value: '42' },
          { label: 'Valid from', value: '2026-01-01' },
          { label: 'Valid until', value: '2056-01-01' },
          { label: 'Signature algorithm', value: 'SHA256withRSA' },
          { label: 'SHA-1', value: 'CD'.repeat(20) },
          { label: 'SHA-256', value: 'EF'.repeat(32) },
        ],
      },
      {
        title: 'Permissions',
        items: [{ label: 'android.permission.INTERNET', value: 'Declared' }],
      },
      {
        title: 'Activities',
        items: [
          { label: 'com.example.demo.MainActivity', value: 'exported: true' },
        ],
      },
    ],
    files: [
      { name: 'AndroidManifest.xml', size: 2048, compressedSize: 1024 },
      { name: 'classes.dex', size: 8192, compressedSize: 4096 },
    ],
    manifest:
      '<manifest package="com.example.demo">\n  <application android:label="Demo application" />\n</manifest>',
    warnings: [
      'Simulated APK report. No file was read and no signature was verified.',
    ],
  };
}

export function createDemoApkService(fail = false): ApkService {
  return {
    async choosePath() {
      return '/demo/sample.apk';
    },
    async analyze(path) {
      if (fail)
        throw new ApkError(
          'invalid_apk',
          'Simulated invalid APK. Choose another file to retry.',
        );
      return demoReport(path);
    },
    async listenDrop() {
      return () => {};
    },
    async install() {
      if (fail)
        throw new ApkError('install_failed', 'Simulated installation failure.');
    },
  };
}
