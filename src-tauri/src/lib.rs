//! Desktop composition root. Feature logic lives outside the Tauri bootstrap.

mod features;
mod logging;
mod reporting;

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
            app.manage(logging::start(&app.path().app_log_dir()?)?);
            log::info!("Application started version={}", app.package_info().version);
            let reporting = reporting::Reporting::new(&app.path().app_config_dir()?);
            app.manage(sentry::init(reporting.options()));
            logging::install_panic_hook();
            app.manage(reporting);
            app.manage(AdbService::new(UsbAdbConnector::new(
                app.path().app_data_dir()?.join("adb"),
            )));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            logging::log_frontend_event,
            features::settings::commands::open_logs_folder,
            reporting::capture_frontend_error,
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
            features::keystore::explorer_commands::explore_keystore,
            features::keystore::commands::choose_keystore_path,
            features::keystore::commands::copy_keystore_text,
            features::keystore::commands::reveal_keystore
        ])
        .build(tauri::generate_context!())
        .expect("failed to initialize Android Tools")
        .run(|app, event| {
            if matches!(event, tauri::RunEvent::Exit) {
                log::info!("Application exiting");
                app.state::<flexi_logger::LoggerHandle>().shutdown();
            }
        });
}
