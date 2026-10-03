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
        .manage(DeviceService::new(UsbDeviceRepository))
        .setup(|app| {
            app.manage(AdbService::new(UsbAdbConnector::new(
                app.path().app_data_dir()?.join("adb"),
            )));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            features::devices::commands::list_devices,
            features::adb::commands::read_android_info,
            features::adb::commands::disconnect_adb
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Android Tools");
}
