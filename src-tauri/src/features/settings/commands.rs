use super::{
    domain::{AppSettings, ErrorCode, ProjectLink, SettingsError},
    infrastructure,
};
use tauri::Manager;
use tauri_plugin_opener::OpenerExt;

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
        infrastructure::set_crash_reporting(&directory, enabled)
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
