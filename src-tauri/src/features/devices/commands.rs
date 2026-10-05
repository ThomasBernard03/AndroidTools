use tauri::State;

use super::{
    application::DeviceService,
    domain::{DeviceError, DeviceErrorCode, DeviceSummary},
};

/// Runs blocking USB discovery on the worker pool, never on the UI thread.
#[tauri::command]
pub async fn list_devices(
    service: State<'_, DeviceService>,
) -> Result<Vec<DeviceSummary>, DeviceError> {
    let service = service.inner().clone();
    crate::logging::observe("list_devices", async move {
        tauri::async_runtime::spawn_blocking(move || service.list())
            .await
            .map_err(|_| DeviceError {
                code: DeviceErrorCode::Internal,
                message: "Device discovery could not finish. Please retry.".into(),
            })?
    })
    .await
}
