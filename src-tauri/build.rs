fn main() {
    tauri_build::try_build(tauri_build::Attributes::new().app_manifest(
        tauri_build::AppManifest::new().commands(&[
            "list_devices",
            "stop_adb_server",
            "get_device_info",
            "read_logcat",
            "clear_logcat",
            "analyze_apk",
            "generate_keystore",
            "sign_apk",
            "list_recent_apks",
            "remove_recent_apk",
            "list_files",
            "preview_file",
            "download_entry",
            "upload_entry",
            "create_directory",
            "delete_entry",
        ]),
    ))
    .expect("Unable to build Tauri application metadata");
}
