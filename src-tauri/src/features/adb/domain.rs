use std::{future::Future, pin::Pin};

use serde::Serialize;

/// Device properties read through an authenticated ADB session. Missing values stay absent.
#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AndroidInfo {
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub android_version: Option<String>,
    pub api_level: Option<String>,
    pub security_patch: Option<String>,
    pub build_id: Option<String>,
    pub architecture: Option<String>,
    pub battery_percent: Option<u8>,
    pub battery_status: Option<String>,
    pub warning: Option<String>,
}

/// Stable error codes allow the UI to distinguish authorization from transport failures.
#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum AdbErrorCode {
    Unauthorized,
    Disconnected,
    UsbAccess,
    IdentityUnavailable,
    Timeout,
    Key,
    Unsupported,
    ReadFailed,
    Internal,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
pub struct AdbError {
    pub code: AdbErrorCode,
    pub message: String,
}

impl AdbError {
    pub fn new(code: AdbErrorCode, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }
}

/// Async boundaries keep the use case independent of native USB and ADB libraries.
pub type AdbFuture<'a, T> = Pin<Box<dyn Future<Output = Result<T, AdbError>> + Send + 'a>>;

pub trait AdbSession: Send + Sync {
    /// Executes the read-only information commands chosen by the application service.
    fn shell<'a>(&'a self, command: &'a str) -> AdbFuture<'a, String>;

    /// Executes a file command with checked exit status and bounded metadata output.
    /// A destination streams binary stdout to disk instead of collecting it in memory.
    fn file_shell<'a>(
        &'a self,
        _command: &'a str,
        _destination: Option<tokio::fs::File>,
    ) -> AdbFuture<'a, FileShellOutput> {
        Box::pin(async {
            Err(AdbError::new(
                AdbErrorCode::Unsupported,
                "File operations are unavailable.",
            ))
        })
    }

    /// Streams a local regular file to an application-owned remote staging path.
    fn push<'a>(&'a self, _local: &'a std::path::Path, _remote: &'a str) -> AdbFuture<'a, ()> {
        Box::pin(async {
            Err(AdbError::new(
                AdbErrorCode::Unsupported,
                "File transfers are unavailable.",
            ))
        })
    }
}

/// Binary-safe shell result. Nonzero remote exits are distinct from transport failures.
pub struct FileShellOutput {
    pub stdout: Vec<u8>,
    pub stderr: String,
    pub exit_code: u8,
}

pub trait AdbConnector: Send + Sync {
    /// Connects to this exact discovered USB attachment, never the first matching model.
    fn connect<'a>(&'a self, connection_id: &'a str) -> AdbFuture<'a, Box<dyn AdbSession>>;
}
