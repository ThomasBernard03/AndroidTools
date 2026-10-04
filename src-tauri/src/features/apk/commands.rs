use super::{
    domain::{self, ApkError, ApkReport},
    infrastructure::NativeApkInspector,
};
use tauri_plugin_dialog::DialogExt;

fn failed() -> ApkError {
    ApkError::new(
        "analysis_failed",
        "APK analysis could not finish. Try another APK.",
    )
}

/// Run archive, resource, certificate and hashing work off the UI thread.
#[tauri::command]
pub async fn analyze_apk(path: String) -> Result<ApkReport, ApkError> {
    tauri::async_runtime::spawn_blocking(move || {
        domain::analyze(std::path::Path::new(&path), &NativeApkInspector)
    })
    .await
    .map_err(|_| failed())?
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
