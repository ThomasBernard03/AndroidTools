fn main() {
    tauri_build::try_build(tauri_build::Attributes::new().app_manifest(
        tauri_build::AppManifest::new().commands(&[
            "list_devices",
            "stop_adb_server",
            "get_device_info",
            "analyze_apk",
            "list_files",
            "preview_file",
        ]),
    ))
    .expect("Unable to build Tauri application metadata");
}
