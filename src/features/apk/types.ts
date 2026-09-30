export interface ApkPermission {
  name: string
  kind: 'requested' | 'requestedSdk23' | 'declared'
  maxSdk: string | null
  protectionLevel: string | null
}

export interface ApkCertificate {
  subject: string
  issuer: string
  serialNumber: string
  validFrom: string
  validUntil: string
  algorithm: string
  sha1: string
  sha256: string
}

export interface ApkSignature {
  scheme: string
  certificates: ApkCertificate[]
}

export interface ApkReport {
  fileName: string
  fileSize: number
  packageName: string | null
  appLabel: string | null
  versionName: string | null
  versionCode: string | null
  minSdk: string | null
  targetSdk: string | null
  manifest: string
  permissions: ApkPermission[]
  signatures: ApkSignature[]
  signatureWarnings: string[]
}
