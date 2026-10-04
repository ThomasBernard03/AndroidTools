use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq)]
pub enum Format {
    #[serde(rename = "JKS")]
    Jks,
    #[serde(rename = "PKCS12")]
    Pkcs12,
}

impl Format {
    pub fn extension(self) -> &'static str {
        match self {
            Self::Jks => "jks",
            Self::Pkcs12 => "p12",
        }
    }
}

/// Only creation of a new store containing one signing key is supported.
/// Passwords are deliberately excluded from Debug and erased on drop.
#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GenerateRequest {
    pub path: String,
    pub format: Format,
    pub password: String,
    pub key_password: String,
    pub alias: String,
    pub validity_years: u32,
    pub common_name: String,
    pub organization: String,
    pub organizational_unit: String,
    pub locality: String,
    pub state: String,
    pub country: String,
}

impl GenerateRequest {
    /// An empty key password reuses the store password; whitespace is a literal password.
    pub fn effective_key_password(&self) -> &str {
        if self.key_password.is_empty() {
            &self.password
        } else {
            &self.key_password
        }
    }
}

impl Drop for GenerateRequest {
    fn drop(&mut self) {
        self.password.zeroize();
        self.key_password.zeroize();
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedKeystore {
    pub path: String,
    pub format: Format,
    pub alias: String,
    pub expires_at: String,
    pub sha1: String,
    pub sha256: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    InvalidInput,
    AlreadyExists,
    WriteFailed,
    GenerationFailed,
    NativeOperationFailed,
}

#[derive(Debug, Serialize)]
pub struct KeystoreError {
    pub code: ErrorCode,
    pub message: String,
    pub field: Option<String>,
}

impl KeystoreError {
    pub fn new(code: ErrorCode, message: &str) -> Self {
        Self {
            code,
            message: message.into(),
            field: None,
        }
    }
    pub fn invalid(field: &str, message: &str) -> Self {
        Self {
            code: ErrorCode::InvalidInput,
            message: message.into(),
            field: Some(field.into()),
        }
    }
}

/// Cryptography is replaceable in application tests; no Tauri runtime is needed.
pub trait KeystoreEncoder {
    fn encode(
        &self,
        request: &GenerateRequest,
    ) -> Result<(Vec<u8>, GeneratedKeystore), KeystoreError>;
}

/// Publishing must be atomic and must never replace an existing file.
pub trait KeystoreFiles {
    fn ensure_available(&self, path: &str) -> Result<(), KeystoreError>;
    fn publish(&self, path: &str, bytes: &[u8]) -> Result<(), KeystoreError>;
}
