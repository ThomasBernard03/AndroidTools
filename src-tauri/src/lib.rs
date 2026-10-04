//! Desktop composition root. Feature logic lives outside the Tauri bootstrap.

mod features;

use features::adb::{application::AdbService, infrastructure::UsbAdbConnector};
use features::devices::{application::DeviceService, infrastructure::UsbDeviceRepository};
use tauri::Manager;

/// Starts the desktop runtime and its main window.
///
/// # Panics
///
/// Panics if the native runtime cannot be initialized or fails while running.
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_opener::init())
        .manage(DeviceService::new(UsbDeviceRepository))
        .setup(|app| {
            app.manage(AdbService::new(UsbAdbConnector::new(
                app.path().app_data_dir()?.join("adb"),
            )));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            features::settings::commands::load_settings,
            features::settings::commands::set_crash_reporting,
            features::settings::commands::open_project_link,
            features::signing::commands::sign_apk,
            features::signing::commands::choose_signing_keystore,
            features::apk::commands::analyze_apk,
            features::apk::commands::choose_apk_path,
            features::devices::commands::list_devices,
            features::adb::commands::read_android_info,
            features::adb::commands::disconnect_adb,
            features::keystore::commands::generate_keystore,
            features::keystore::commands::choose_keystore_path,
            features::keystore::commands::copy_keystore_text,
            features::keystore::commands::reveal_keystore
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Android Tools");
}
