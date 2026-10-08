use super::{
    application::AdbService,
    domain::{AdbError, AndroidInfo},
};
use tauri::State;
use tauri_plugin_dialog::DialogExt;

/// Saves the displayed PNG, independently of the phone's current screen or connection.
#[tauri::command]
pub async fn save_device_screen(
    app: tauri::AppHandle,
    image: String,
    connection_id: String,
) -> Result<bool, AdbError> {
    crate::logging::observe("save_device_screen", async move {
        tauri::async_runtime::spawn_blocking(move || {
            super::screenshot::save(&image, || {
                // USB connection IDs contain colons; keep the suggested name portable.
                let identifier: String = connection_id
                    .chars()
                    .take(100)
                    .map(|character| {
                        if character.is_ascii_alphanumeric() || character == '-' || character == '_'
                        {
                            character
                        } else {
                            '-'
                        }
                    })
                    .collect();
                let filename = format!(
                    "device-preview_{}_{}.png",
                    identifier,
                    chrono::Local::now().format("%Y-%m-%d_%H-%M-%S")
                );
                app.dialog()
                    .file()
                    .set_title("Save screen preview")
                    .add_filter("PNG image", &["png"])
                    .set_file_name(filename)
                    .blocking_save_file()
                    .map(|file| {
                        file.into_path().map_err(|_| {
                            super::domain::AdbError::new(
                                super::domain::AdbErrorCode::SaveFailed,
                                "Choose a local destination for the preview.",
                            )
                        })
                    })
                    .transpose()
            })
        })
        .await
        .map_err(|_| {
            AdbError::new(
                super::domain::AdbErrorCode::Internal,
                "Saving the preview could not finish. Please retry.",
            )
        })?
    })
    .await
}

/// Establishes ADB for the selected USB attachment and returns Android information.
#[tauri::command]
pub async fn read_android_info(
    service: State<'_, AdbService>,
    connection_id: String,
) -> Result<AndroidInfo, AdbError> {
    crate::logging::observe("read_android_info", service.read(&connection_id)).await
}

/// Captures the selected device's default display as a PNG data URL.
#[tauri::command]
pub async fn capture_device_screen(
    service: State<'_, AdbService>,
    connection_id: String,
) -> Result<String, AdbError> {
    crate::logging::observe(
        "capture_device_screen",
        service.capture_screen(&connection_id),
    )
    .await
}

/// Releases the selected ADB session and its USB interface.
#[tauri::command]
pub async fn disconnect_adb(service: State<'_, AdbService>) -> Result<(), AdbError> {
    service.disconnect().await;
    log::info!("ADB session released");
    Ok(())
}
