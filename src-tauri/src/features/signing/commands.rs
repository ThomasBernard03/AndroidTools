use super::{application, domain::*, infrastructure::NativeSigner};
use tauri_plugin_dialog::DialogExt;

fn native_error() -> SigningError {
    SigningError::new(
        ErrorCode::NativeOperationFailed,
        "The desktop operation could not finish. Please retry.",
    )
}

/// Signs on a blocking worker, then asks where to publish the prepared APK.
#[tauri::command]
pub async fn sign_apk(
    app: tauri::AppHandle,
    request: SignRequest,
) -> Result<Option<String>, SigningError> {
    tauri::async_runtime::spawn_blocking(move || {
        application::sign_and_save(&request, &NativeSigner, |name| {
            app.dialog()
                .file()
                .set_title("Save signed APK")
                .add_filter("Android package", &["apk"])
                .set_file_name(name)
                .blocking_save_file()
                .map(|p| {
                    p.into_path()
                        .map(|p| p.to_string_lossy().into_owned())
                        .map_err(|_| native_error())
                })
                .transpose()
        })
    })
    .await
    .map_err(|_| native_error())?
}

#[tauri::command]
pub async fn choose_signing_keystore(
    app: tauri::AppHandle,
) -> Result<Option<String>, SigningError> {
    tauri::async_runtime::spawn_blocking(move || {
        app.dialog()
            .file()
            .set_title("Choose signing keystore")
            .add_filter("Keystore", &["jks", "keystore", "p12", "pfx", "pkcs12"])
            .blocking_pick_file()
            .map(|p| {
                p.into_path()
                    .map(|p| p.to_string_lossy().into_owned())
                    .map_err(|_| native_error())
            })
            .transpose()
    })
    .await
    .map_err(|_| native_error())?
}
