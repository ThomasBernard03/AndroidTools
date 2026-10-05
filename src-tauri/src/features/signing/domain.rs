use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

/// Credentials are never logged and Rust-owned password buffers are erased on drop.
#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignRequest {
    pub apk_path: String,
    pub keystore_path: String,
    pub alias: String,
    pub password: String,
    pub key_password: String,
}

impl Drop for SignRequest {
    fn drop(&mut self) {
        self.password.zeroize();
        self.key_password.zeroize();
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    InvalidInput,
    InvalidKeystore,
    InvalidApk,
    SigningFailed,
    WriteFailed,
    NativeOperationFailed,
}

#[derive(Debug, Serialize)]
pub struct SigningError {
    pub code: ErrorCode,
    pub message: String,
}

impl SigningError {
    pub fn new(code: ErrorCode, message: &str) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }
}

/// A prepared artifact owns its temporary resources until publication or cancellation.
pub trait SignedArtifact {
    fn save(self, destination: &str) -> Result<(), SigningError>;
}

pub trait ApkSigner {
    type Artifact: SignedArtifact;
    fn sign(&self, request: &SignRequest) -> Result<Self::Artifact, SigningError>;
}
