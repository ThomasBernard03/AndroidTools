export interface SignRequest {
  apkPath: string;
  keystorePath: string;
  alias: string;
  password: string;
  keyPassword: string;
}

export interface SigningService {
  chooseApk(): Promise<string | null>;
  chooseKeystore(): Promise<string | null>;
  /** Signs first, then opens the native save dialog. Null means cancellation. */
  signAndSave(request: SignRequest): Promise<string | null>;
  copy(text: string): Promise<void>;
  reveal(path: string): Promise<void>;
}

export class SigningError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'SigningError';
  }
}

export function signedFilename(path: string): string {
  const filename = path.split(/[\\/]/).pop() ?? '';
  return `${filename.replace(/\.apk$/i, '')}-signed.apk`;
}
