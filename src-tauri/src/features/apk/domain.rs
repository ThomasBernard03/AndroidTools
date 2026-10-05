use serde::Serialize;
use std::path::Path;

/// Stable, presentation-neutral inspection report. Missing values remain explicit.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApkReport {
    pub path: String,
    pub size: u64,
    /// Inline raster preview of the resolved application icon, when supported.
    pub icon_data_url: Option<String>,
    pub signature: SignatureVerification,
    pub sha256: String,
    pub sections: Vec<Section>,
    pub files: Vec<ArchiveFile>,
    pub manifest: String,
    pub warnings: Vec<String>,
}

/// Cryptographic integrity is separate from certificate identity or Android install policy.
#[derive(Debug, Serialize)]
pub struct SignatureVerification {
    pub status: VerificationStatus,
    pub schemes: Vec<String>,
    pub message: String,
}

#[derive(Debug, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum VerificationStatus {
    Verified,
    Invalid,
    Unverified,
    Unsigned,
}

#[derive(Debug, Serialize)]
pub struct Section {
    pub title: String,
    pub items: Vec<InfoItem>,
}

#[derive(Debug, Serialize)]
pub struct InfoItem {
    pub label: String,
    pub value: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ArchiveFile {
    pub name: String,
    pub size: u64,
    pub compressed_size: u64,
}

/// Replaceable analysis boundary; implementations must not execute APK contents.
pub trait ApkInspector {
    fn inspect(&self, path: &Path) -> Result<ApkReport, ApkError>;
}

#[derive(Debug, Serialize)]
pub struct ApkError {
    pub code: &'static str,
    pub message: &'static str,
}

impl ApkError {
    pub fn new(code: &'static str, message: &'static str) -> Self {
        Self { code, message }
    }
}

/// Validates the supported input before invoking an external inspector.
pub fn analyze(path: &Path, inspector: &impl ApkInspector) -> Result<ApkReport, ApkError> {
    if !path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("apk"))
    {
        return Err(ApkError::new(
            "invalid_extension",
            "Choose a single .apk file.",
        ));
    }
    inspector.inspect(path)
}
