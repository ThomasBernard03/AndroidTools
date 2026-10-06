use super::{
    domain::{self, ApkError, ApkReport},
    infrastructure::NativeApkInspector,
};
use tauri_plugin_dialog::DialogExt;

/// Installs the analyzed bytes using the shared, serialized ADB connection.
#[tauri::command]
pub async fn install_apk(
    adb: tauri::State<'_, crate::features::adb::application::AdbService>,
    connection_id: String,
    path: String,
    sha256: String,
) -> Result<(), crate::features::adb::domain::AdbError> {
    crate::logging::observe("install_apk", async move {
        let snapshot = tauri::async_runtime::spawn_blocking(move || {
            super::installation::snapshot(std::path::Path::new(&path), &sha256)
        })
        .await
        .map_err(|_| {
            crate::features::adb::domain::AdbError::new(
                crate::features::adb::domain::AdbErrorCode::Internal,
                "The APK could not be prepared for installation.",
            )
        })??;
        adb.with_session(&connection_id, |session| {
            Box::pin(async move { super::installation::install(session, snapshot.path()).await })
        })
        .await
    })
    .await
}

fn failed() -> ApkError {
    ApkError::new(
        "analysis_failed",
        "APK analysis could not finish. Try another APK.",
    )
}

/// Run archive, resource, certificate and hashing work off the UI thread.
#[tauri::command]
pub async fn analyze_apk(path: String) -> Result<ApkReport, ApkError> {
    crate::logging::observe("analyze_apk", async move {
        tauri::async_runtime::spawn_blocking(move || {
            domain::analyze(std::path::Path::new(&path), &NativeApkInspector)
        })
        .await
        .map_err(|_| failed())?
    })
    .await
}

#[tauri::command]
pub async fn choose_apk_path(app: tauri::AppHandle) -> Result<Option<String>, ApkError> {
    tauri::async_runtime::spawn_blocking(move || {
        app.dialog()
            .file()
            .set_title("Analyze APK")
            .add_filter("Android package", &["apk"])
            .blocking_pick_file()
            .map(|file| {
                file.into_path()
                    .map(|p| p.to_string_lossy().into_owned())
                    .map_err(|_| failed())
            })
            .transpose()
    })
    .await
    .map_err(|_| failed())?
}
