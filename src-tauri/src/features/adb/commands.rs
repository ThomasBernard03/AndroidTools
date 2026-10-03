use super::{
    application::AdbService,
    domain::{AdbError, AndroidInfo},
};
use tauri::State;

/// Establishes ADB for the selected USB attachment and returns Android information.
#[tauri::command]
pub async fn read_android_info(
    service: State<'_, AdbService>,
    connection_id: String,
) -> Result<AndroidInfo, AdbError> {
    service.read(&connection_id).await
}

/// Releases the selected ADB session and its USB interface.
#[tauri::command]
pub async fn disconnect_adb(service: State<'_, AdbService>) -> Result<(), AdbError> {
    service.disconnect().await;
    Ok(())
}
