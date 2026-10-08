use serde::{Deserialize, Serialize};

use crate::features::adb::domain::{AdbError, AdbErrorCode};

/// File explorer failures are separate from ADB transport failures.
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FileError {
    pub code: String,
    pub message: String,
    pub partial: bool,
}

impl FileError {
    pub fn new(code: &str, message: impl Into<String>) -> Self {
        Self {
            code: code.into(),
            message: message.into(),
            partial: false,
        }
    }

    pub fn partial(mut self) -> Self {
        self.partial = true;
        self
    }
}

impl From<AdbError> for FileError {
    fn from(error: AdbError) -> Self {
        let code = match error.code {
            AdbErrorCode::Unauthorized => "unauthorized",
            AdbErrorCode::Disconnected => "disconnected",
            AdbErrorCode::UsbAccess => "usb_access",
            AdbErrorCode::IdentityUnavailable => "identity_unavailable",
            AdbErrorCode::Timeout => "timeout",
            AdbErrorCode::Key => "adb_key",
            AdbErrorCode::Unsupported => "unsupported",
            AdbErrorCode::ReadFailed => "adb_failed",
            AdbErrorCode::SaveFailed => "save_failed",
            AdbErrorCode::Internal => "internal",
        };
        Self::new(code, error.message)
    }
}

impl From<std::io::Error> for FileError {
    fn from(error: std::io::Error) -> Self {
        let code = match error.kind() {
            std::io::ErrorKind::AlreadyExists => "already_exists",
            std::io::ErrorKind::PermissionDenied => "local_permission",
            std::io::ErrorKind::NotFound => "local_not_found",
            _ => "local_io",
        };
        Self::new(code, format!("Local file operation failed: {error}"))
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum EntryKind {
    Directory,
    File,
    Symlink,
    Other,
}

/// Metadata never follows symbolic links. Package entries have no filesystem metadata.
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FileEntry {
    pub name: String,
    pub kind: EntryKind,
    pub size: Option<u64>,
    pub modified_at: Option<i64>,
    pub permissions: Option<String>,
}

impl FileEntry {
    pub fn directory(name: &str) -> Self {
        Self {
            name: name.into(),
            kind: EntryKind::Directory,
            size: None,
            modified_at: None,
            permissions: None,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct FileListing {
    pub path: String,
    pub entries: Vec<FileEntry>,
}

#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Mutation {
    Rename,
    Delete,
    CreateDirectory,
}
