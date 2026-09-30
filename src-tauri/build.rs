fn main() {
    tauri_build::try_build(tauri_build::Attributes::new().app_manifest(
        tauri_build::AppManifest::new().commands(&["list_devices", "get_device_info"]),
    ))
    .expect("Unable to build Tauri application metadata");
}
