use serde::{Deserialize, Serialize};

/// Persisted application preferences. Reporting defaults to off.
#[derive(Debug, Default, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    pub crash_reporting_enabled: bool,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    StorageFailed,
    OpenFailed,
    UpdaterUnavailable,
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    UpdateFailed,
}

#[derive(Debug, Serialize)]
pub struct SettingsError {
    pub code: ErrorCode,
    pub message: &'static str,
}

impl SettingsError {
    pub fn storage() -> Self {
        Self {
            code: ErrorCode::StorageFailed,
            message: "Application settings could not be read or saved. Please retry.",
        }
    }
}

/// Only these fixed project destinations may be opened through settings IPC.
#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ProjectLink {
    Repository,
    Issue,
    Changelog,
}

impl ProjectLink {
    pub fn url(&self) -> &'static str {
        match self {
            Self::Repository => "https://github.com/ThomasBernard03/AndroidTools",
            Self::Issue => "https://github.com/ThomasBernard03/AndroidTools/issues/new/choose",
            Self::Changelog => "https://github.com/ThomasBernard03/AndroidTools/releases",
        }
    }
}
