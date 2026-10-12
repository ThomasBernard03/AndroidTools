import assert from 'node:assert/strict';
import { createHash, generateKeyPairSync, sign } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import {
  configureWindows,
  verifyWindowsInstaller,
  windowsManifest,
} from './windows-release.mjs';

const config = {
  version: '2026.6.1',
  bundle: { macOS: { bundleVersion: '45', minimumSystemVersion: '10.13' } },
};
const changelog = '## [2026.06.1] - 2026-06-01\n\nWindows support.\n';

function fixture() {
  const { publicKey, privateKey } = generateKeyPairSync('ed25519');
  const keyId = Buffer.from('0102030405060708', 'hex');
  const keyPacket = Buffer.concat([
    Buffer.from('Ed'),
    keyId,
    publicKey.export({ format: 'der', type: 'spki' }).subarray(-32),
  ]);
  const key = Buffer.from(
    `untrusted comment: test key\n${keyPacket.toString('base64')}\n`,
  ).toString('base64');
  const bytes = Buffer.from('installer fixture');
  const payload = sign(
    null,
    createHash('blake2b512').update(bytes).digest(),
    privateKey,
  );
  const packet = Buffer.concat([Buffer.from('ED'), keyId, payload]);
  const comment = 'timestamp:1\tfile:installer.exe\tprehashed';
  const global = sign(
    null,
    Buffer.concat([payload, Buffer.from(comment)]),
    privateKey,
  );
  const signature = Buffer.from(
    `untrusted comment: test signature\n${packet.toString('base64')}\ntrusted comment: ${comment}\n${global.toString('base64')}\n`,
  ).toString('base64');
  return { key, signature, bytes };
}

test('Windows feed uses SemVer for comparisons and historical padded download tags', () => {
  const { bytes, signature, key } = fixture();
  const manifest = windowsManifest(
    config,
    changelog,
    signature,
    key,
    bytes,
    new Date('2026-06-01T12:00:00Z'),
  );
  assert.equal(manifest.version, '2026.6.1');
  assert.equal(manifest.pub_date, '2026-06-01T12:00:00.000Z');
  assert.equal(manifest.notes, 'Windows support.\n');
  assert.equal(manifest.platforms['windows-x86_64'].signature, signature);
  assert.equal(
    manifest.platforms['windows-x86_64'].url,
    'https://github.com/ThomasBernard03/AndroidTools/releases/download/2026.06.1/AndroidTools-2026.06.1-windows-x64-setup.exe',
  );
});

test('rejects changed installers, wrong keys, damaged signatures and missing release notes', () => {
  const { bytes, signature, key } = fixture();
  assert.throws(() =>
    verifyWindowsInstaller(Buffer.from('changed'), signature, key),
  );
  assert.throws(() => verifyWindowsInstaller(bytes, signature, fixture().key));
  const changedComment = Buffer.from(
    Buffer.from(signature, 'base64')
      .toString()
      .replace('timestamp:1', 'timestamp:2'),
  ).toString('base64');
  assert.throws(() => verifyWindowsInstaller(bytes, changedComment, key));
  assert.throws(() => verifyWindowsInstaller(bytes, 'invalid', key));
  assert.throws(() => windowsManifest(config, '', signature, key, bytes));
});

test('release configuration requires a real Tauri public key and leaves its template unchanged', () => {
  const template = {
    plugins: {
      updater: { pubkey: '', endpoints: ['https://example.com/latest.json'] },
    },
  };
  const { key } = fixture();
  assert.equal(configureWindows(template, key).plugins.updater.pubkey, key);
  assert.equal(template.plugins.updater.pubkey, '');
  for (const invalid of [
    '',
    undefined,
    'z9EBcFEFrJ5Bi6oiODtO2k6fo7X61gTEKmiuG3+Qxwg=',
  ]) {
    assert.throws(() => configureWindows(template, invalid));
  }
});

test('verifies signatures produced by the installed Tauri CLI and rejects modified bytes', () => {
  const directory = mkdtempSync(join(tmpdir(), 'android-tools-updater-'));
  try {
    const cli = join(process.cwd(), 'node_modules/@tauri-apps/cli/tauri.js');
    const keyPath = join(directory, 'test.key');
    const installer = join(directory, 'installer.exe');
    writeFileSync(installer, 'signed installer fixture');
    execFileSync(
      process.execPath,
      [cli, 'signer', 'generate', '--ci', '-w', keyPath],
      { stdio: 'pipe' },
    );
    execFileSync(
      process.execPath,
      [cli, 'signer', 'sign', '-f', keyPath, installer],
      {
        stdio: 'pipe',
        env: {
          ...process.env,
          CI: 'true',
          TAURI_SIGNING_PRIVATE_KEY_PASSWORD: '',
        },
      },
    );
    const key = readFileSync(`${keyPath}.pub`, 'utf8');
    const signature = readFileSync(`${installer}.sig`, 'utf8');
    verifyWindowsInstaller(readFileSync(installer), signature, key);
    assert.throws(() =>
      verifyWindowsInstaller(Buffer.from('tampered installer'), signature, key),
    );
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
