use super::{
    application,
    domain::*,
    infrastructure::{NativeEncoder, NativeFiles},
};
use tauri_plugin_clipboard_manager::ClipboardExt;
use tauri_plugin_dialog::DialogExt;
use tauri_plugin_opener::OpenerExt;

fn native_error() -> KeystoreError {
    KeystoreError::new(
        ErrorCode::NativeOperationFailed,
        "The desktop operation could not finish. Please retry.",
    )
}

/// Crypto and disk operations run outside the UI thread.
#[tauri::command]
pub async fn generate_keystore(
    request: GenerateRequest,
) -> Result<GeneratedKeystore, KeystoreError> {
    tauri::async_runtime::spawn_blocking(move || {
        application::generate(&request, &NativeEncoder, &NativeFiles)
    })
    .await
    .map_err(|_| native_error())?
}

#[tauri::command]
pub async fn choose_keystore_path(
    app: tauri::AppHandle,
    format: Format,
) -> Result<Option<String>, KeystoreError> {
    tauri::async_runtime::spawn_blocking(move || {
        app.dialog()
            .file()
            .set_title("Save keystore")
            .add_filter("Keystore", &[format.extension()])
            .set_file_name(format!("upload.{}", format.extension()))
            .blocking_save_file()
            .map(|path| {
                path.into_path()
                    .map(|p| p.to_string_lossy().into_owned())
                    .map_err(|_| native_error())
            })
            .transpose()
    })
    .await
    .map_err(|_| native_error())?
}

#[tauri::command]
pub fn copy_keystore_text(app: tauri::AppHandle, text: String) -> Result<(), KeystoreError> {
    app.clipboard().write_text(text).map_err(|_| native_error())
}

#[tauri::command]
pub fn reveal_keystore(app: tauri::AppHandle, path: String) -> Result<(), KeystoreError> {
    app.opener()
        .reveal_item_in_dir(path)
        .map_err(|_| native_error())
}
