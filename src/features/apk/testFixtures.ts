import type { ApkReport } from './types'

export const apkReport = (fileName = 'demo.apk'): ApkReport => ({
  fileName,
  fileSize: 1024,
  packageName: 'com.example.demo',
  appLabel: 'Demo',
  versionName: '1.2',
  versionCode: '17',
  minSdk: '24',
  targetSdk: '35',
  manifest:
    '<manifest package="com.example.demo"><application label="&lt;script&gt;" /></manifest>',
  permissions: [
    { name: 'android.permission.CAMERA', kind: 'requested', maxSdk: '32', protectionLevel: null },
    { name: 'com.example.ACCESS', kind: 'declared', maxSdk: null, protectionLevel: 'signature' },
  ],
  signatures: [
    {
      scheme: 'v2',
      certificates: [
        {
          subject: 'CN=Demo',
          issuer: 'CN=Demo',
          serialNumber: '0123',
          validFrom: '2026-01-01',
          validUntil: '2030-01-01',
          algorithm: 'RSA',
          sha1: 'abcd',
          sha256: '1234',
        },
      ],
    },
  ],
  signatureWarnings: [],
})

export function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}
