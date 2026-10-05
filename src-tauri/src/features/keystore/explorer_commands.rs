use super::{
    explorer::{self, ExploreError, ExploreRequest, KeystoreReport},
    explorer_native::NativeInspector,
};

/// Explores a keystore on a blocking worker; passwords and private keys are never returned.
#[tauri::command]
pub async fn explore_keystore(request: ExploreRequest) -> Result<KeystoreReport, ExploreError> {
    tauri::async_runtime::spawn_blocking(move || explorer::explore(&request, &NativeInspector))
        .await
        .map_err(|_| {
            ExploreError::new(
                "native_failed",
                "The keystore operation could not finish. Please retry.",
            )
        })?
}
