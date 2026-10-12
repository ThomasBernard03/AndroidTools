// Windows configuration and signed release metadata; publication stays in Actions.
import { createHash, createPublicKey, verify } from 'node:crypto';
import {
  copyFileSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { releaseNotes, releaseVersion } from './release.mjs';

function decode(value) {
  if (
    typeof value !== 'string' ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(value.trim())
  ) {
    throw new Error('Expected a base64 Tauri signing value');
  }
  return Buffer.from(value.trim(), 'base64');
}

function publicKeyBytes(key) {
  const lines = decode(key).toString('utf8').trim().split(/\r?\n/);
  const bytes = decode(lines[1]);
  if (
    lines.length !== 2 ||
    !lines[0].startsWith('untrusted comment: ') ||
    bytes.length !== 42 ||
    bytes.subarray(0, 2).toString() !== 'Ed'
  ) {
    throw new Error('Invalid Tauri public key');
  }
  return bytes;
}

export function configureWindows(config, key) {
  publicKeyBytes(key);
  const result = structuredClone(config);
  result.plugins.updater.pubkey = key.trim();
  return result;
}

// Tauri signatures are base64-encoded Minisign documents, not Sparkle signatures.
export function verifyWindowsInstaller(bytes, signature, key) {
  const publicBytes = publicKeyBytes(key);
  const lines = decode(signature).toString('utf8').trim().split(/\r?\n/);
  if (
    lines.length !== 4 ||
    !lines[0].startsWith('untrusted comment: ') ||
    !lines[2].startsWith('trusted comment: ')
  ) {
    throw new Error('Invalid Tauri signature document');
  }
  const packet = decode(lines[1]);
  if (
    packet.length !== 74 ||
    packet.subarray(0, 2).toString() !== 'ED' ||
    !packet.subarray(2, 10).equals(publicBytes.subarray(2, 10))
  ) {
    throw new Error('The installer signature does not match the Tauri key');
  }
  const publicKey = createPublicKey({
    key: Buffer.concat([
      Buffer.from('302a300506032b6570032100', 'hex'),
      publicBytes.subarray(10),
    ]),
    format: 'der',
    type: 'spki',
  });
  const payload = packet.subarray(10);
  if (
    !verify(
      null,
      createHash('blake2b512').update(bytes).digest(),
      publicKey,
      payload,
    ) ||
    !verify(
      null,
      Buffer.concat([payload, Buffer.from(lines[2].slice(17))]),
      publicKey,
      decode(lines[3]),
    )
  ) {
    throw new Error('The Windows installer signature is invalid');
  }
}

export function windowsManifest(
  config,
  changelog,
  signature,
  key,
  bytes,
  date = new Date(),
) {
  verifyWindowsInstaller(bytes, signature, key);
  const { version } = releaseVersion(config);
  return {
    version: config.version,
    notes: releaseNotes(changelog, version),
    pub_date: date.toISOString(),
    platforms: {
      'windows-x86_64': {
        signature: signature.trim(),
        url: `https://github.com/ThomasBernard03/AndroidTools/releases/download/${version}/AndroidTools-${version}-windows-x64-setup.exe`,
      },
    },
  };
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const key = process.env.TAURI_UPDATER_PUBLIC_KEY;
  const config = JSON.parse(readFileSync('src-tauri/tauri.conf.json', 'utf8'));
  const { version } = releaseVersion(config);
  const artifact = `AndroidTools-${version}-windows-x64-setup.exe`;
  switch (process.argv[2]) {
    case 'configure': {
      const template = JSON.parse(
        readFileSync('src-tauri/tauri.windows.release.conf.json', 'utf8'),
      );
      writeFileSync(
        process.argv[3],
        JSON.stringify(configureWindows(template, key), null, 2) + '\n',
      );
      break;
    }
    case 'metadata': {
      const directory = 'src-tauri/target/release/bundle/nsis';
      const installers = readdirSync(directory).filter((file) =>
        file.endsWith('-setup.exe'),
      );
      if (installers.length !== 1)
        throw new Error('Expected exactly one Windows x64 NSIS installer');
      const installer = join(directory, installers[0]);
      const signature = readFileSync(`${installer}.sig`, 'utf8');
      const manifest = windowsManifest(
        config,
        readFileSync('CHANGELOG.md', 'utf8'),
        signature,
        key,
        readFileSync(installer),
      );
      copyFileSync(installer, artifact);
      copyFileSync(`${installer}.sig`, `${artifact}.sig`);
      writeFileSync('latest.json', JSON.stringify(manifest, null, 2) + '\n');
      break;
    }
    case 'verify-published': {
      const signature = readFileSync(`${artifact}.sig`, 'utf8');
      const published = JSON.parse(readFileSync('latest.json', 'utf8'));
      const expected = windowsManifest(
        config,
        readFileSync('CHANGELOG.md', 'utf8'),
        signature,
        key,
        readFileSync(artifact),
        new Date(published.pub_date),
      );
      if (JSON.stringify(published) !== JSON.stringify(expected)) {
        throw new Error(
          'Published Windows metadata does not match this release',
        );
      }
      break;
    }
    default:
      throw new Error('Expected configure, metadata or verify-published');
  }
}
