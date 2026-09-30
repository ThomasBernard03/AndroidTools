use std::sync::Arc;

use crate::devices::{DeviceInfo, DeviceService, DeviceSummary, ServiceError};

#[tauri::command]
pub async fn list_files(
    device_id: String,
    path: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<crate::devices::FileListing, ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.list_files(&device_id, &path))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn preview_file(
    device_id: String,
    path: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<crate::devices::FilePreview, ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.preview_file(&device_id, &path))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn analyze_apk(path: String) -> Result<crate::apk::ApkReport, crate::apk::ApkError> {
    tauri::async_runtime::spawn_blocking(move || crate::apk::analyze(std::path::Path::new(&path)))
        .await
        .map_err(|error| {
            crate::apk::ApkError::new(
                "analysis",
                "L’analyse de l’APK a échoué.",
                error.to_string(),
            )
        })?
}

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
