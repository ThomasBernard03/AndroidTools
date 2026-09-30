use serde::Serialize;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApkError {
    pub code: &'static str,
    pub message: &'static str,
    pub details: String,
}

impl ApkError {
    pub fn new(code: &'static str, message: &'static str, details: impl Into<String>) -> Self {
        Self {
            code,
            message,
            details: details.into(),
        }
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApkReport {
    pub file_name: String,
    pub file_size: u64,
    pub package_name: Option<String>,
    pub app_label: Option<String>,
    pub version_name: Option<String>,
    pub version_code: Option<String>,
    pub min_sdk: Option<String>,
    pub target_sdk: Option<String>,
    pub manifest: String,
    pub permissions: Vec<Permission>,
    pub signatures: Vec<SignatureInfo>,
    pub signature_warnings: Vec<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Permission {
    pub name: String,
    pub kind: &'static str,
    pub max_sdk: Option<String>,
    pub protection_level: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SignatureInfo {
    pub scheme: &'static str,
    pub certificates: Vec<Certificate>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Certificate {
    pub subject: String,
    pub issuer: String,
    pub serial_number: String,
    pub valid_from: String,
    pub valid_until: String,
    pub algorithm: String,
    pub sha1: String,
    pub sha256: String,
}

impl From<apk_info::CertificateInfo> for Certificate {
    fn from(value: apk_info::CertificateInfo) -> Self {
        Self {
            subject: value.subject,
            issuer: value.issuer,
            serial_number: value.serial_number,
            valid_from: value.valid_from,
            valid_until: value.valid_until,
            algorithm: value.signature_type,
            sha1: value.sha1_fingerprint,
            sha256: value.sha256_fingerprint,
        }
    }
}
