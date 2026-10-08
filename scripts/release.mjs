// Pure release metadata helpers. Build, signing and publication stay in the workflow.
import { DOMParser, XMLSerializer } from '@xmldom/xmldom';
import { createPublicKey, verify } from 'node:crypto';
import { appendFileSync, readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const sparkle = 'http://www.andymatuschak.org/xml-namespaces/sparkle';
const repository = 'https://github.com/ThomasBernard03/AndroidTools';
const publicKey = 'z9EBcFEFrJ5Bi6oiODtO2k6fo7X61gTEKmiuG3+Qxwg=';

export function verifyArchive(bytes, signature, key = publicKey) {
  // Sparkle stores the raw Ed25519 key; Node expects an RFC 8410 SPKI wrapper.
  const wrappedKey = createPublicKey({
    key: Buffer.concat([
      Buffer.from('302a300506032b6570032100', 'hex'),
      Buffer.from(key, 'base64'),
    ]),
    format: 'der',
    type: 'spki',
  });
  if (!verify(null, bytes, wrappedKey, Buffer.from(signature, 'base64'))) {
    throw new Error(
      'The DMG signature does not match the historical Sparkle public key',
    );
  }
}

function parseFeed(xml) {
  const document = new DOMParser({
    onError: (level, message) => {
      throw new Error(`Invalid appcast (${level}): ${message}`);
    },
  }).parseFromString(xml, 'application/xml');
  const channels = document.getElementsByTagName('channel');
  if (channels.length !== 1) throw new Error('Expected one appcast channel');
  return { document, channel: channels[0] };
}

function integer(value) {
  if (
    !/^[1-9]\d*$/.test(String(value)) ||
    !Number.isSafeInteger(Number(value))
  ) {
    throw new Error('The Sparkle build must be a positive integer');
  }
  return Number(value);
}

export function releaseVersion(config) {
  const match = /^(\d{4})\.([1-9]|1[0-2])\.(0|[1-9]\d*)$/.exec(config.version);
  if (!match) throw new Error('Use calendar SemVer, for example 2026.6.1');
  return {
    version: `${match[1]}.${match[2].padStart(2, '0')}.${match[3]}`,
    build: integer(config.bundle.macOS.bundleVersion),
    minimumSystemVersion: config.bundle.macOS.minimumSystemVersion,
  };
}

export function prepare(config, xml) {
  const release = releaseVersion(config);
  const { channel } = parseFeed(xml);
  let latest = 0;
  let alreadyPublished = false;
  for (const item of Array.from(channel.getElementsByTagName('item'))) {
    const build = integer(
      item.getElementsByTagNameNS(sparkle, 'version')[0]?.textContent,
    );
    const version = item.getElementsByTagNameNS(
      sparkle,
      'shortVersionString',
    )[0]?.textContent;
    latest = Math.max(latest, build);
    if (build === release.build || version === release.version) {
      if (build !== release.build || version !== release.version) {
        throw new Error('A published version or build cannot be reused');
      }
      alreadyPublished = true;
    }
  }
  if (release.build < latest)
    throw new Error('Build is older than the published appcast');
  return { ...release, needed: !alreadyPublished };
}

export function updateFeed(config, xml, metadata) {
  const release = prepare(config, xml);
  if (
    metadata.version !== release.version ||
    metadata.build !== release.build
  ) {
    throw new Error('Artifact metadata does not match the release');
  }
  if (!/^[A-Za-z0-9+/]{86}==$/.test(metadata.signature)) {
    throw new Error('Invalid Sparkle Ed25519 signature');
  }
  integer(metadata.length);
  if (!Number.isFinite(Date.parse(metadata.pubDate)))
    throw new Error('Invalid publication date');
  if (!release.needed) return xml;
  const { document, channel } = parseFeed(xml);
  const item = document.createElement('item');
  const values = {
    title: `Version ${release.version}`,
    'sparkle:version': String(release.build),
    'sparkle:shortVersionString': release.version,
    'sparkle:minimumSystemVersion': release.minimumSystemVersion,
    'sparkle:releaseNotesLink': `${repository}/releases/tag/${release.version}`,
    pubDate: metadata.pubDate,
  };
  for (const [name, value] of Object.entries(values)) {
    const element = document.createElementNS(
      name.startsWith('sparkle:') ? sparkle : null,
      name,
    );
    element.appendChild(document.createTextNode(value));
    item.appendChild(document.createTextNode('\n      '));
    item.appendChild(element);
  }
  const enclosure = document.createElement('enclosure');
  enclosure.setAttribute(
    'url',
    `${repository}/releases/download/${release.version}/AndroidTools-${release.version}-macos.dmg`,
  );
  enclosure.setAttributeNS(sparkle, 'sparkle:edSignature', metadata.signature);
  enclosure.setAttributeNS(sparkle, 'sparkle:os', 'macos');
  enclosure.setAttribute('length', String(metadata.length));
  enclosure.setAttribute('type', 'application/octet-stream');
  item.appendChild(document.createTextNode('\n      '));
  item.appendChild(enclosure);
  item.appendChild(document.createTextNode('\n    '));
  const first = channel.getElementsByTagName('item')[0] ?? null;
  channel.insertBefore(item, first);
  channel.insertBefore(document.createTextNode('\n    '), first);
  return new XMLSerializer().serializeToString(document);
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  const config = JSON.parse(readFileSync('src-tauri/tauri.conf.json', 'utf8'));
  const packageVersion = JSON.parse(
    readFileSync('package.json', 'utf8'),
  ).version;
  const cargoVersion = /^version = "([^"]+)"$/m.exec(
    readFileSync('src-tauri/Cargo.toml', 'utf8'),
  )?.[1];
  if (config.version !== packageVersion || config.version !== cargoVersion) {
    throw new Error('Tauri, npm and Cargo versions must match');
  }
  const xml = readFileSync('appcast.xml', 'utf8');
  switch (process.argv[2]) {
    case 'prepare': {
      const result = prepare(config, xml);
      const output = Object.entries(result)
        .map(([key, value]) => `${key}=${value}\n`)
        .join('');
      if (process.env.GITHUB_OUTPUT)
        appendFileSync(process.env.GITHUB_OUTPUT, output);
      process.stdout.write(output);
      break;
    }
    case 'metadata': {
      const signature = /sparkle:edSignature="([^"]+)"/.exec(
        process.env.SIGNATURE_OUTPUT ?? '',
      )?.[1];
      const metadata = {
        ...releaseVersion(config),
        signature,
        length: Number(process.env.FILE_SIZE),
        pubDate: new Date().toUTCString(),
      };
      updateFeed(config, xml, metadata);
      const archive = readFileSync(
        `AndroidTools-${metadata.version}-macos.dmg`,
      );
      if (archive.length !== metadata.length)
        throw new Error('Incorrect DMG length');
      verifyArchive(archive, metadata.signature);
      writeFileSync(
        'release-metadata.json',
        JSON.stringify(metadata, null, 2) + '\n',
      );
      break;
    }
    case 'feed': {
      const metadata = JSON.parse(
        readFileSync('release-metadata.json', 'utf8'),
      );
      writeFileSync('appcast.xml', updateFeed(config, xml, metadata));
      break;
    }
    default:
      throw new Error('Expected prepare, metadata or feed');
  }
}
