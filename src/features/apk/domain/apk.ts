export interface ApkReport {
  path: string;
  size: number;
  iconDataUrl: string | null;
  signature: {
    status: 'verified' | 'invalid' | 'unverified' | 'unsigned';
    schemes: string[];
    message: string;
  };
  sha256: string;
  sections: {
    title: string;
    items: { label: string; value: string | null }[];
  }[];
  files: { name: string; size: number; compressedSize: number }[];
  manifest: string;
  warnings: string[];
}

export type ApkDrop =
  { type: 'enter' | 'leave' } | { type: 'drop'; paths: string[] };

export interface ApkService {
  choosePath(): Promise<string | null>;
  analyze(path: string): Promise<ApkReport>;
  install(connectionId: string, path: string, sha256: string): Promise<void>;
  listenDrop(handler: (event: ApkDrop) => void): Promise<() => void>;
}

export class ApkError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'ApkError';
  }
}
