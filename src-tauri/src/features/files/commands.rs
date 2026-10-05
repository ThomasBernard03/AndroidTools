use super::{application, domain::*, paths, transfers};
use crate::features::adb::application::AdbService;
use tauri_plugin_dialog::DialogExt;

#[tauri::command]
pub async fn list_files(
    service: tauri::State<'_, AdbService>,
    device_id: String,
    path: String,
) -> Result<FileListing, FileError> {
    service
        .with_session(&device_id, move |session| {
            Box::pin(async move { application::list(session, &path).await })
        })
        .await
}

#[tauri::command]
pub async fn mutate_file(
    service: tauri::State<'_, AdbService>,
    device_id: String,
    path: String,
    operation: Mutation,
    name: String,
) -> Result<(), FileError> {
    service
        .with_session(&device_id, move |session| {
            Box::pin(async move { application::mutate(session, &path, operation, &name).await })
        })
        .await
}

/// The native picker selects one source or a destination directory. Cancellation is explicit.
#[tauri::command]
pub async fn transfer_file(
    app: tauri::AppHandle,
    service: tauri::State<'_, AdbService>,
    device_id: String,
    path: String,
    upload: bool,
    directory: bool,
) -> Result<bool, FileError> {
    let path = paths::normalize(&path)?;
    let entry = if upload {
        paths::writable(&path)?;
        None
    } else {
        let (_, entry) = paths::target(&path)?;
        paths::local_name(entry)?;
        Some(entry.to_owned())
    };
    let selected = tauri::async_runtime::spawn_blocking(move || {
        let dialog = app.dialog().file().set_title(if upload {
            "Choose an upload source"
        } else {
            "Choose the download destination folder"
        });
        let selected = if !upload || directory {
            dialog.blocking_pick_folder()
        } else {
            dialog.blocking_pick_file()
        };
        selected
            .map(|value| {
                value
                    .into_path()
                    .map_err(|_| FileError::new("local_path", "Select a local filesystem path."))
            })
            .transpose()
    })
    .await
    .map_err(|_| FileError::new("internal", "The file picker could not finish."))??;
    let Some(mut local) = selected else {
        return Ok(false);
    };
    if let Some(entry) = entry {
        local.push(entry);
    }
    service
        .with_session(&device_id, move |session| {
            Box::pin(async move {
                let result = if upload {
                    transfers::upload(session, &path, local).await
                } else {
                    transfers::download(session, &path, local).await
                };
                result.map_err(FileError::partial)
            })
        })
        .await?;
    Ok(true)
}
