import assert from 'node:assert/strict';
import { generateKeyPairSync, sign } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import {
  prepare,
  releaseVersion,
  updateFeed,
  verifyArchive,
} from './release.mjs';

const xml = readFileSync(new URL('../appcast.xml', import.meta.url), 'utf8');
const config = {
  version: '2027.6.1',
  bundle: { macOS: { bundleVersion: '100', minimumSystemVersion: '10.13' } },
};
const metadata = {
  version: '2027.06.1',
  build: 100,
  signature: Buffer.alloc(64).toString('base64'),
  length: 123456,
  pubDate: 'Mon, 05 Oct 2026 12:00:00 GMT',
};

test('rejects a changed archive or a different Sparkle signing key', () => {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const rawKey = publicKey
    .export({ format: 'der', type: 'spki' })
    .subarray(-32)
    .toString('base64');
  const archive = Buffer.from('simulated DMG');
  const signature = sign(null, archive, privateKey).toString('base64');
  verifyArchive(archive, signature, rawKey);
  assert.throws(() =>
    verifyArchive(Buffer.from('changed DMG'), signature, rawKey),
  );
  assert.throws(() => verifyArchive(archive, signature));
});

test(
  'verifies signatures emitted by the pinned Sparkle tool',
  {
    skip: !process.env.SPARKLE_SIGN_TOOL,
  },
  () => {
    const { privateKey, publicKey } = generateKeyPairSync('ed25519');
    const seed = privateKey
      .export({ format: 'der', type: 'pkcs8' })
      .subarray(-32);
    const rawKey = publicKey
      .export({ format: 'der', type: 'spki' })
      .subarray(-32)
      .toString('base64');
    const directory = mkdtempSync(join(tmpdir(), 'sparkle-sign-test-'));
    try {
      const bytes = Buffer.from('deterministic update archive fixture');
      const path = join(directory, 'update.zip');
      writeFileSync(path, bytes);
      const output = execFileSync(
        process.env.SPARKLE_SIGN_TOOL,
        ['--ed-key-file', '-', path],
        {
          input: seed.toString('base64'),
          encoding: 'utf8',
        },
      );
      const signature = /sparkle:edSignature="([^"]+)"/.exec(output)?.[1];
      assert.ok(signature);
      verifyArchive(bytes, signature, rawKey);
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  },
);

test('calendar SemVer preserves historical zero-padded release tags', () => {
  assert.equal(releaseVersion(config).version, '2027.06.1');
  assert.throws(() => releaseVersion({ ...config, version: '2027.06.1' }));
  assert.throws(() =>
    releaseVersion({ ...config, bundle: { macOS: { bundleVersion: '0' } } }),
  );
});

test('appcast retains history and advertises the signed artifact with its minimum OS', () => {
  const result = updateFeed(config, xml, metadata);
  assert.equal(
    (result.match(/<item>/g) ?? []).length,
    (xml.match(/<item>/g) ?? []).length + 1,
  );
  assert.ok(
    result.indexOf('Version 2027.06.1') < result.indexOf('Version 2026.10.2'),
  );
  assert.ok(
    result.includes(
      'releases/download/2027.06.1/AndroidTools-2027.06.1-macos.dmg',
    ),
  );
  assert.ok(
    result.includes(
      '<sparkle:minimumSystemVersion>10.13</sparkle:minimumSystemVersion>',
    ),
  );
  assert.ok(result.includes(`sparkle:edSignature="${metadata.signature}"`));
  assert.ok(result.includes('length="123456"'));
  assert.equal(prepare(config, result).needed, false);
  assert.equal(updateFeed(config, result, metadata), result);
});

test('rejects reused builds, reused versions and downgrades', () => {
  const result = updateFeed(config, xml, metadata);
  assert.throws(
    () => prepare({ ...config, version: '2027.6.2' }, result),
    /reused/,
  );
  assert.throws(
    () =>
      prepare(
        { ...config, bundle: { macOS: { bundleVersion: '101' } } },
        result,
      ),
    /reused/,
  );
  assert.throws(
    () =>
      prepare(
        {
          ...config,
          version: '2027.5.1',
          bundle: { macOS: { bundleVersion: '99' } },
        },
        result,
      ),
    /older/,
  );
});

test('rejects malformed feeds and mismatched or invalid artifact metadata', () => {
  assert.throws(() => prepare(config, '<rss/>'), /channel/);
  assert.throws(() => prepare(config, '<rss><channel></rss>'));
  for (const patch of [
    { build: 101 },
    { version: '2027.06.2' },
    { signature: '' },
    { length: 0 },
    { pubDate: 'invalid' },
  ]) {
    assert.throws(() => updateFeed(config, xml, { ...metadata, ...patch }));
  }
});
