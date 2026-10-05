export interface ExploreRequest {
  path: string;
  password: string;
  keyAlias: string | null;
  keyPassword: string;
}
export interface CertificateInfo {
  subject: string;
  issuer: string;
  serial: string;
  validFrom: string;
  validUntil: string;
  sha1: string;
  sha256: string;
}
export interface ExploredEntry {
  alias: string | null;
  kind: 'private_key' | 'trusted_certificate' | 'certificate';
  keyStatus: 'not_checked' | 'not_applicable' | 'verified' | 'failed';
  certificates: CertificateInfo[];
}
export interface KeystoreReport {
  format: 'jks' | 'pkcs12';
  entries: ExploredEntry[];
  limitation: string | null;
}
export interface KeystoreExplorerService {
  choose(): Promise<string | null>;
  inspect(request: ExploreRequest): Promise<KeystoreReport>;
  copy(text: string): Promise<void>;
}
export class ExplorerError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'ExplorerError';
  }
}
