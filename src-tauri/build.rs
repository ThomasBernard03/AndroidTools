fn main() {
    println!("cargo:rerun-if-env-changed=SENTRY_DSN");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos")
        && std::env::var_os("CARGO_FEATURE_MACOS_UPDATER").is_some()
    {
        println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path/../Frameworks");
    }
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
            "get_settings",
            "set_crash_reporting",
            "open_app_log",
            "open_project_link",
            "check_app_updates",
        ]),
    ))
    .expect("Unable to build Tauri application metadata");
}
