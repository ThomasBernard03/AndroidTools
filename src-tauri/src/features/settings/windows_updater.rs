use std::time::Duration;

use tauri_plugin_dialog::{DialogExt, MessageDialogButtons};
use tauri_plugin_updater::{Update, UpdaterExt};

use super::{
    domain::{ErrorCode, SettingsError},
    updates::{self, PendingUpdate, UpdateBackend},
};

// Startup and manual checks share one gate, including the confirmation dialog.
static CHECK: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

fn failed() -> SettingsError {
    SettingsError {
        code: ErrorCode::UpdateFailed,
        message: "The update could not be checked, verified or installed. Check your connection and retry.",
    }
}

struct NativeBackend(tauri::AppHandle);

impl PendingUpdate for Update {
    fn version(&self) -> &str {
        &self.version
    }

    async fn install(self) -> Result<(), SettingsError> {
        // Tauri verifies the downloaded signature before launching NSIS. On Windows
        // it exits the application and the installer handles installation/relaunch.
        self.download_and_install(|_, _| {}, || {})
            .await
            .map_err(|_| failed())
    }
}

impl UpdateBackend for NativeBackend {
    type Update = Update;

    async fn discover(&self) -> Result<Option<Update>, SettingsError> {
        self.0
            .updater_builder()
            .timeout(Duration::from_secs(120))
            .on_before_exit(|| log::logger().flush())
            .build()
            .map_err(|_| failed())?
            .check()
            .await
            .map_err(|_| failed())
    }

    async fn confirm(&self, version: &str) -> Result<bool, SettingsError> {
        let dialog = self.0.dialog()
            .message(format!("Android Tools {version} is available. Download and install it now? The application will close to install the update. Finish any device transfers first."))
            .title("Android Tools update")
            .buttons(MessageDialogButtons::OkCancelCustom("Install update".into(), "Later".into()));
        tauri::async_runtime::spawn_blocking(move || dialog.blocking_show())
            .await
            .map_err(|_| failed())
    }

    async fn notify_current(&self) -> Result<(), SettingsError> {
        let dialog = self
            .0
            .dialog()
            .message("Android Tools is up to date.")
            .title("Android Tools update");
        tauri::async_runtime::spawn_blocking(move || dialog.blocking_show())
            .await
            .map_err(|_| failed())?;
        Ok(())
    }
}

/// Checks the signed Windows release feed, without overlapping another check.
pub(crate) async fn check(app: tauri::AppHandle, interactive: bool) -> Result<(), SettingsError> {
    let _guard = CHECK.try_lock().map_err(|_| SettingsError {
        code: ErrorCode::UpdateFailed,
        message: "An update check is already running. Please wait and retry.",
    })?;
    let configured = app
        .config()
        .plugins
        .0
        .get("updater")
        .and_then(|value| value.get("pubkey"))
        .and_then(serde_json::Value::as_str)
        .is_some_and(|key| !key.trim().is_empty());
    if !configured {
        return Err(SettingsError {
            code: ErrorCode::UpdaterUnavailable,
            message: "This build does not have a Windows update signing key configured.",
        });
    }
    updates::check(&NativeBackend(app), interactive).await
}
