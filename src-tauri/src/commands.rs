use std::sync::Arc;

use crate::devices::{DeviceInfo, DeviceService, DeviceSummary, ServiceError};

#[tauri::command]
pub async fn read_logcat(
    device_id: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<Vec<crate::devices::LogEntry>, ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.read_logcat(&device_id))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn clear_logcat(
    device_id: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<(), ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.clear_logcat(&device_id))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn download_entry(
    device_id: String,
    path: String,
    local_path: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<(), ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || {
        service.download_entry(&device_id, &path, std::path::Path::new(&local_path))
    })
    .await
    .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn upload_entry(
    device_id: String,
    path: String,
    local_path: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<(), ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || {
        service.upload_entry(&device_id, &path, std::path::Path::new(&local_path))
    })
    .await
    .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn create_directory(
    device_id: String,
    path: String,
    name: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<(), ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.create_directory(&device_id, &path, &name))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn delete_entry(
    device_id: String,
    path: String,
    service: tauri::State<'_, Arc<DeviceService>>,
) -> Result<(), ServiceError> {
    let service = Arc::clone(service.inner());
    tauri::async_runtime::spawn_blocking(move || service.delete_entry(&device_id, &path))
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

#[tauri::command]
pub async fn generate_keystore(
    request: crate::apk_tools::KeystoreRequest,
) -> Result<String, crate::apk::ApkError> {
    tauri::async_runtime::spawn_blocking(move || crate::apk_tools::generate_keystore(request))
        .await
        .map_err(|e| {
            crate::apk::ApkError::new("apk_tools", "Génération impossible.", e.to_string())
        })?
}

#[tauri::command]
pub async fn sign_apk(
    request: crate::apk_tools::SignRequest,
) -> Result<String, crate::apk::ApkError> {
    tauri::async_runtime::spawn_blocking(move || crate::apk_tools::sign_apk(request))
        .await
        .map_err(|e| {
            crate::apk::ApkError::new("apk_tools", "Signature impossible.", e.to_string())
        })?
}

#[tauri::command]
pub async fn stop_adb_server() -> Result<bool, ServiceError> {
    tauri::async_runtime::spawn_blocking(crate::devices::stop_adb_server)
        .await
        .map_err(|error| ServiceError::internal(error.to_string()))?
}

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
pub async fn analyze_apk(
    path: String,
    history: tauri::State<'_, Arc<crate::apk::history::ApkHistory>>,
) -> Result<ApkAnalysis, crate::apk::ApkError> {
    let history = Arc::clone(history.inner());
    tauri::async_runtime::spawn_blocking(move || {
        let report = crate::apk::analyze(std::path::Path::new(&path))?;
        let history_error = history.remember(&path).err();
        Ok(ApkAnalysis {
            report,
            history_error,
        })
    })
    .await
    .map_err(|error| {
        crate::apk::ApkError::new(
            "analysis",
            "L’analyse de l’APK a échoué.",
            error.to_string(),
        )
    })?
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ApkAnalysis {
    #[serde(flatten)]
    report: crate::apk::ApkReport,
    history_error: Option<crate::apk::ApkError>,
}

#[tauri::command]
pub async fn list_recent_apks(
    history: tauri::State<'_, Arc<crate::apk::history::ApkHistory>>,
) -> Result<Vec<String>, crate::apk::ApkError> {
    let history = Arc::clone(history.inner());
    tauri::async_runtime::spawn_blocking(move || history.list())
        .await
        .map_err(crate::apk::history::history_error)?
}

#[tauri::command]
pub async fn remove_recent_apk(
    path: String,
    history: tauri::State<'_, Arc<crate::apk::history::ApkHistory>>,
) -> Result<(), crate::apk::ApkError> {
    let history = Arc::clone(history.inner());
    tauri::async_runtime::spawn_blocking(move || history.remove(&path))
        .await
        .map_err(crate::apk::history::history_error)?
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
