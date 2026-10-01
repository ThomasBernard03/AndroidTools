mod apk;
mod apk_tools;
mod commands;
mod devices;

use tauri::Manager;

pub fn run() {
    let builder = tauri::Builder::default();
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    let builder = builder.plugin(tauri_plugin_sparkle_updater::init());

    builder
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            let key_path = app.path().app_data_dir()?.join("adbkey.pem");
            app.manage(devices::DeviceService::new(key_path));
            app.manage(std::sync::Arc::new(apk::history::ApkHistory(
                app.path().app_data_dir()?.join("apk-history.sqlite"),
            )));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::list_devices,
            commands::stop_adb_server,
            commands::get_device_info,
            commands::read_logcat,
            commands::clear_logcat,
            commands::list_files,
            commands::preview_file,
            commands::download_entry,
            commands::upload_entry,
            commands::create_directory,
            commands::delete_entry,
            commands::analyze_apk,
            commands::generate_keystore,
            commands::sign_apk,
            commands::list_recent_apks,
            commands::remove_recent_apk
        ])
        .run(tauri::generate_context!())
        .expect("Unable to start Android Tools");
}
