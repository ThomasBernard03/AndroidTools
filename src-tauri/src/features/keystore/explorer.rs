//! Read-only exploration contracts and input validation, independent of the desktop runtime.
use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExploreRequest {
    pub path: String,
    pub password: String,
    pub key_alias: Option<String>,
    pub key_password: String,
}

impl Drop for ExploreRequest {
    fn drop(&mut self) {
        self.password.zeroize();
        self.key_password.zeroize();
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CertificateInfo {
    pub subject: String,
    pub issuer: String,
    pub serial: String,
    pub valid_from: String,
    pub valid_until: String,
    pub sha1: String,
    pub sha256: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExploredEntry {
    pub alias: Option<String>,
    pub kind: &'static str,
    pub key_status: &'static str,
    pub certificates: Vec<CertificateInfo>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct KeystoreReport {
    pub format: &'static str,
    pub entries: Vec<ExploredEntry>,
    pub limitation: Option<&'static str>,
}

#[derive(Debug, Serialize)]
pub struct ExploreError {
    pub code: &'static str,
    pub message: &'static str,
}

impl ExploreError {
    pub fn new(code: &'static str, message: &'static str) -> Self {
        Self { code, message }
    }
}

/// Reads a snapshot and verifies store protection without modifying the source file.
pub trait KeystoreInspector {
    fn inspect(&self, request: &ExploreRequest) -> Result<KeystoreReport, ExploreError>;
}

pub fn explore(
    request: &ExploreRequest,
    inspector: &impl KeystoreInspector,
) -> Result<KeystoreReport, ExploreError> {
    if request.path.trim().is_empty()
        || request.path.len() > 4096
        || request.password.len() > 1024
        || request.key_password.len() > 1024
        || request
            .key_alias
            .as_ref()
            .is_some_and(|a| a.is_empty() || a.len() > 1024)
    {
        return Err(ExploreError::new(
            "invalid_input",
            "Enter a keystore path and credentials of at most 1024 bytes.",
        ));
    }
    inspector.inspect(request)
}
