use super::application::{self, LogcatService};
use super::history::{Page, SearchRequest, SearchResult, Snapshot};
use crate::features::adb::{application::AdbService, domain::AdbError};
use tauri::State;

#[tauri::command]
pub async fn start_logcat(
    adb: State<'_, AdbService>,
    service: State<'_, LogcatService>,
    connection_id: String,
    package: String,
) -> Result<u32, AdbError> {
    service.start(&adb, &connection_id, package).await
}

#[tauri::command]
pub async fn read_logcat(
    service: State<'_, LogcatService>,
    token: u32,
) -> Result<Snapshot, AdbError> {
    service.read(token).await
}

#[tauri::command]
pub async fn page_logcat(
    service: State<'_, LogcatService>,
    token: u32,
    minimum: char,
    start: u64,
    grouped: bool,
) -> Result<Page, AdbError> {
    service.page(token, minimum, start, grouped).await
}

#[tauri::command]
pub async fn search_logcat(
    service: State<'_, LogcatService>,
    token: u32,
    request: SearchRequest,
) -> Result<SearchResult, AdbError> {
    service.search(token, request).await
}

#[tauri::command]
pub async fn pause_logcat(service: State<'_, LogcatService>, token: u32) -> Result<(), AdbError> {
    service.pause(token).await;
    Ok(())
}

#[tauri::command]
pub async fn stop_logcat(service: State<'_, LogcatService>, token: u32) -> Result<(), AdbError> {
    service.stop(token).await;
    Ok(())
}

#[tauri::command]
pub async fn list_logcat_packages(
    adb: State<'_, AdbService>,
    connection_id: String,
) -> Result<Vec<String>, AdbError> {
    application::list_packages(&adb, &connection_id).await
}

#[tauri::command]
pub async fn clear_logcat(
    adb: State<'_, AdbService>,
    connection_id: String,
) -> Result<(), AdbError> {
    application::clear(&adb, &connection_id).await
}
