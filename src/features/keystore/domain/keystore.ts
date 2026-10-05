export type KeystoreFormat = 'JKS' | 'PKCS12';

export interface GenerateRequest {
  path: string;
  format: KeystoreFormat;
  password: string;
  keyPassword: string;
  alias: string;
  validityYears: number;
  commonName: string;
  organizationalUnit: string;
  organization: string;
  locality: string;
  state: string;
  country: string;
}

export interface GeneratedKeystore {
  path: string;
  format: KeystoreFormat;
  alias: string;
  expiresAt: string;
  sha1: string;
  sha256: string;
}

export interface KeystoreService {
  choosePath(format: KeystoreFormat): Promise<string | null>;
  generate(request: GenerateRequest): Promise<GeneratedKeystore>;
  copy(text: string): Promise<void>;
  reveal(path: string): Promise<void>;
}

export class KeystoreError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly field?: string,
  ) {
    super(message);
    this.name = 'KeystoreError';
  }
}

export function extension(format: KeystoreFormat) {
  return format === 'JKS' ? 'jks' : 'p12';
}

export function expirationDate(years: number, now = new Date()): string {
  if (!Number.isInteger(years) || years < 1 || years > 100) return '';
  const year = now.getUTCFullYear() + years;
  const month = now.getUTCMonth();
  const day = Math.min(
    now.getUTCDate(),
    new Date(Date.UTC(year, month + 1, 0)).getUTCDate(),
  );
  return new Date(Date.UTC(year, month, day)).toISOString().slice(0, 10);
}

export function validateRequest(
  request: GenerateRequest,
): Record<string, string> {
  const errors: Record<string, string> = {};
  if (
    !/^(\/|[a-zA-Z]:[\\/]|\\\\)/.test(request.path) ||
    !request.path.endsWith(`.${extension(request.format)}`)
  )
    errors.path = `Choose an absolute path ending in .${extension(request.format)}.`;
  for (const field of ['password', 'keyPassword'] as const) {
    if (field === 'keyPassword' && !request.keyPassword) continue;
    if (!/^[\x20-\x7e]{6,128}$/.test(request[field]))
      errors[field] =
        'Use 6–128 printable ASCII characters for Java/Android compatibility.';
  }
  if (
    request.format === 'PKCS12' &&
    request.keyPassword &&
    request.password !== request.keyPassword
  )
    errors.keyPassword = 'PKCS12 uses the keystore password for the key.';
  if (!/^[a-z0-9._-]{1,64}$/.test(request.alias))
    errors.alias =
      'Use 1–64 lowercase letters, numbers, dots, underscores or hyphens.';
  if (
    !Number.isInteger(request.validityYears) ||
    request.validityYears < 1 ||
    request.validityYears > 100
  )
    errors.validityYears = 'Choose a validity between 1 and 100 years.';
  for (const field of [
    'commonName',
    'organizationalUnit',
    'organization',
    'locality',
    'state',
  ] as const) {
    if (
      new TextEncoder().encode(request[field]).length > 128 ||
      Array.from(request[field]).some((c) => {
        const code = c.codePointAt(0)!;
        return code < 32 || (code >= 127 && code <= 159);
      })
    )
      errors[field] = 'Use at most 128 UTF-8 bytes without control characters.';
  }
  if (!request.commonName.trim())
    errors.commonName = 'Enter a certificate name.';
  if (request.country && !/^[A-Z]{2}$/.test(request.country))
    errors.country = 'Enter a two-letter country code.';
  return errors;
}

/** Each of the 64 symbols is equally likely; Web Crypto supplies 144 bits of entropy. */
export function generatePassword(): string {
  const alphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  return Array.from(
    crypto.getRandomValues(new Uint8Array(24)),
    (byte) => alphabet[byte & 63],
  ).join('');
}
