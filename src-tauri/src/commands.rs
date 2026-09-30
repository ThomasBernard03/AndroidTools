use std::sync::Arc;

use crate::devices::{DeviceInfo, DeviceService, DeviceSummary, ServiceError};

#[tauri::command]
pub async fn list_devices() -> Result<Vec<DeviceSummary>, ServiceError> {
    tauri::async_runtime::spawn_blocking(crate::devices::list_devices)
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn get_device_info(
    device_id: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<DeviceInfo, ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.get_info(&device_id))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}
