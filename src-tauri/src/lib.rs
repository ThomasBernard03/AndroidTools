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
    let builder = tauri::Builder::default();
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    let builder = builder.plugin(tauri_plugin_sparkle_updater::init());
    #[cfg(all(windows, feature = "windows-updater"))]
    let builder = builder.plugin(tauri_plugin_updater::Builder::new().build());

    builder
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_opener::init())
        .manage(DeviceService::new(UsbDeviceRepository))
        .manage(features::logcat::application::LogcatService::default())
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
            #[cfg(all(windows, feature = "windows-updater"))]
            {
                let handle = app.handle().clone();
                tauri::async_runtime::spawn(async move {
                    let _ = logging::observe(
                        "startup_update_check",
                        features::settings::windows_updater::check(handle, false),
                    )
                    .await;
                });
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            features::logcat::commands::start_logcat,
            features::logcat::commands::read_logcat,
            features::logcat::commands::page_logcat,
            features::logcat::commands::search_logcat,
            features::logcat::commands::stop_logcat,
            features::logcat::commands::pause_logcat,
            features::logcat::commands::list_logcat_packages,
            features::logcat::commands::clear_logcat,
            features::files::commands::list_files,
            features::files::commands::preview_file,
            features::files::commands::mutate_file,
            features::files::commands::transfer_file,
            features::files::commands::upload_files,
            logging::log_frontend_event,
            features::settings::commands::open_logs_folder,
            reporting::capture_frontend_error,
            features::settings::commands::load_settings,
            features::settings::commands::set_crash_reporting,
            features::settings::commands::open_project_link,
            features::settings::commands::check_app_updates,
            features::signing::commands::sign_apk,
            features::signing::commands::choose_signing_keystore,
            features::apk::commands::analyze_apk,
            features::apk::commands::install_apk,
            features::apk::commands::choose_apk_path,
            features::devices::commands::list_devices,
            features::adb::commands::read_android_info,
            features::adb::commands::capture_device_screen,
            features::adb::commands::save_device_screen,
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
