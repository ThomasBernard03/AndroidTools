use super::{
    domain::{AppSettings, ErrorCode, ProjectLink, SettingsError},
    infrastructure,
};
use tauri::Manager;
use tauri_plugin_opener::OpenerExt;

/// Hands update discovery and installation to Sparkle's native UI.
/// Development binaries and other platforms never simulate a successful check.
#[tauri::command]
pub fn check_app_updates(app: tauri::AppHandle) -> Result<(), SettingsError> {
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    {
        use tauri_plugin_sparkle_updater::SparkleUpdaterExt;
        if let Some(updater) = app.sparkle_updater() {
            return updater.check_for_updates().map_err(|_| SettingsError {
                code: ErrorCode::UpdateFailed,
                message: "The update check could not be started. Please retry.",
            });
        }
    }
    let _ = app;
    Err(SettingsError {
        code: ErrorCode::UpdaterUnavailable,
        message: "Updates require an installed macOS release of Android Tools.",
    })
}

/// Opens only the application's own log directory, never a webview-supplied path.
#[tauri::command]
pub async fn open_logs_folder(app: tauri::AppHandle) -> Result<(), SettingsError> {
    crate::logging::observe("open_logs_folder", async move {
        let directory = app
            .path()
            .app_log_dir()
            .map_err(|_| SettingsError::storage())?;
        tauri::async_runtime::spawn_blocking(move || {
            std::fs::create_dir_all(&directory).map_err(|_| SettingsError::storage())?;
            app.opener()
                .open_path(directory.to_string_lossy(), None::<&str>)
                .map_err(|_| SettingsError {
                    code: ErrorCode::OpenFailed,
                    message: "The logs folder could not be opened. Please retry.",
                })
        })
        .await
        .map_err(|_| SettingsError::storage())?
    })
    .await
}

#[tauri::command]
pub async fn load_settings(app: tauri::AppHandle) -> Result<AppSettings, SettingsError> {
    let directory = app
        .path()
        .app_config_dir()
        .map_err(|_| SettingsError::storage())?;
    tauri::async_runtime::spawn_blocking(move || infrastructure::load(&directory))
        .await
        .map_err(|_| SettingsError::storage())?
}

#[tauri::command]
pub async fn set_crash_reporting(
    app: tauri::AppHandle,
    enabled: bool,
) -> Result<AppSettings, SettingsError> {
    let directory = app
        .path()
        .app_config_dir()
        .map_err(|_| SettingsError::storage())?;
    tauri::async_runtime::spawn_blocking(move || {
        app.state::<crate::reporting::Reporting>()
            .save(&directory, enabled)
    })
    .await
    .map_err(|_| SettingsError::storage())?
}

#[tauri::command]
pub fn open_project_link(app: tauri::AppHandle, link: ProjectLink) -> Result<(), SettingsError> {
    app.opener()
        .open_url(link.url(), None::<&str>)
        .map_err(|_| SettingsError {
            code: ErrorCode::OpenFailed,
            message: "GitHub could not be opened in your browser. Please retry.",
        })
}
