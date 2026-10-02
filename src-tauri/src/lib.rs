mod apk;
mod apk_tools;
mod commands;
mod devices;
mod settings;

use tauri::Manager;

pub fn run() {
    let builder = tauri::Builder::default();
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    let builder = builder.plugin(tauri_plugin_sparkle_updater::init());

    builder
        .plugin(tauri_plugin_opener::init())
        .plugin(
            tauri_plugin_log::Builder::new()
                .level(log::LevelFilter::Info)
                .max_file_size(5_000_000)
                .rotation_strategy(tauri_plugin_log::RotationStrategy::KeepOne)
                .targets([tauri_plugin_log::Target::new(
                    tauri_plugin_log::TargetKind::LogDir {
                        file_name: Some("android-tools".into()),
                    },
                )])
                .build(),
        )
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            app.manage(settings::Settings::load(
                app.path().app_data_dir()?.join("settings.json"),
                &app.package_info().version.to_string(),
            )?);
            log::info!("Starting Android Tools {}", app.package_info().version);
            let key_path = app.path().app_data_dir()?.join("adbkey.pem");
            app.manage(devices::DeviceService::new(key_path));
            app.manage(std::sync::Arc::new(apk::history::ApkHistory(
                app.path().app_data_dir()?.join("apk-history.sqlite"),
            )));
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            settings::get_settings,
            settings::set_crash_reporting,
            settings::open_app_log,
            settings::open_project_link,
            settings::check_app_updates,
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
