mod apk;
mod commands;
mod devices;

use tauri::Manager;

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            let key_path = app.path().app_data_dir()?.join("adbkey.pem");
            app.manage(devices::DeviceService::new(key_path));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::list_devices,
            commands::get_device_info,
            commands::list_files,
            commands::preview_file,
            commands::analyze_apk
        ])
        .run(tauri::generate_context!())
        .expect("Unable to start Android Tools");
}
