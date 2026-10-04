//! Local diagnostics. Only deliberate application events are persisted; dependency
//! logs and arbitrary IPC payloads are excluded to protect credentials and device data.

use flexi_logger::{Cleanup, Criterion, FileSpec, Logger, LoggerHandle, Naming, WriteMode};
use std::{future::Future, path::Path, time::Instant};

const MAX_FILE_BYTES: u64 = 5 * 1024 * 1024;
const ARCHIVE_COUNT: usize = 5;

fn configured_logger(
    directory: &Path,
    max_bytes: u64,
) -> Result<Logger, flexi_logger::FlexiLoggerError> {
    Ok(Logger::try_with_str("off,android_tools_lib=info")?
        .log_to_file(
            FileSpec::default()
                .directory(directory)
                .basename("android-tools")
                .suppress_timestamp(),
        )
        .append()
        .use_utc()
        .format(|writer, now, record| {
            writeln!(
                writer,
                "{} {:5} [{}] {}",
                now.format_rfc3339(),
                record.level(),
                record.target(),
                record.args()
            )
        })
        .rotate(
            Criterion::Size(max_bytes),
            Naming::Numbers,
            Cleanup::KeepLogFiles(ARCHIVE_COUNT),
        )
        .cleanup_in_background_thread(false)
        .write_mode(WriteMode::Async))
}

/// Starts the process logger. Retain its handle until the desktop runtime exits.
pub fn start(directory: &Path) -> Result<LoggerHandle, flexi_logger::FlexiLoggerError> {
    configured_logger(directory, MAX_FILE_BYTES)?.start()
}

/// Chain the existing panic handler (including Sentry) without logging panic
/// payloads, which may contain secrets. Install after other panic integrations.
pub fn install_panic_hook() {
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        if let Some(location) = info.location() {
            log::error!("Rust panic at {}:{}", location.file(), location.line());
        } else {
            log::error!("Rust panic at unknown location");
        }
        log::logger().flush();
        previous(info);
    }));
}

/// Records an operation's outcome and duration without formatting its input,
/// output or error, which may contain passwords, paths or USB identifiers.
pub async fn observe<T, E>(
    operation: &'static str,
    work: impl Future<Output = Result<T, E>>,
) -> Result<T, E> {
    let started = Instant::now();
    let result = work.await;
    let elapsed_ms = started.elapsed().as_millis();
    if result.is_ok() {
        log::info!("operation={operation} outcome=success elapsed_ms={elapsed_ms}");
    } else {
        log::warn!("operation={operation} outcome=failure elapsed_ms={elapsed_ms}");
    }
    result
}

/// A bounded vocabulary prevents accidental logging of webview secrets.
#[derive(serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FrontendEvent {
    VueError,
    UnhandledError,
    UnhandledRejection,
}

#[tauri::command]
pub fn log_frontend_event(event: FrontendEvent) {
    let kind = match event {
        FrontendEvent::VueError => "vue_error",
        FrontendEvent::UnhandledError => "unhandled_error",
        FrontendEvent::UnhandledRejection => "unhandled_rejection",
    };
    log::error!("frontend event={kind}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rotates_bounds_retention_and_appends_after_restart() {
        let directory = tempfile::tempdir().expect("temporary logs");
        let (logger, handle) = configured_logger(directory.path(), 256)
            .expect("config")
            .build()
            .expect("logger");
        for _ in 0..100 {
            logger.log(
                &log::Record::builder()
                    .args(format_args!("rotation test event"))
                    .level(log::Level::Info)
                    .target("android_tools_lib::test")
                    .build(),
            );
        }
        handle.shutdown();
        drop(logger);
        let files: Vec<_> = std::fs::read_dir(directory.path())
            .expect("logs")
            .map(|entry| entry.expect("file").path())
            .collect();
        assert_eq!(files.len(), ARCHIVE_COUNT + 1);
        let active = files
            .iter()
            .find(|path| path.to_string_lossy().contains("rCURRENT"))
            .expect("active log");
        let before = std::fs::read_to_string(active).expect("read log");
        assert!(before.contains("INFO"));
        assert!(before.contains("[android_tools_lib::test]"));
        let (logger, handle) = configured_logger(directory.path(), MAX_FILE_BYTES)
            .expect("config")
            .build()
            .expect("restart");
        logger.log(
            &log::Record::builder()
                .args(format_args!("restart event"))
                .level(log::Level::Info)
                .target("android_tools_lib::test")
                .build(),
        );
        logger.log(
            &log::Record::builder()
                .args(format_args!("dependency secret"))
                .level(log::Level::Error)
                .target("external_dependency")
                .build(),
        );
        handle.shutdown();
        let after = std::fs::read_to_string(active).expect("read appended log");
        assert!(after.starts_with(&before));
        assert!(after.contains("restart event"));
        assert!(!after.contains("dependency secret"));
    }

    #[test]
    fn rejects_arbitrary_frontend_messages() {
        assert!(serde_json::from_str::<FrontendEvent>("\"password=secret\"").is_err());
        assert!(serde_json::from_str::<FrontendEvent>("\"vue_error\"").is_ok());
    }

    #[test]
    fn reports_an_unwritable_destination() {
        let file = tempfile::NamedTempFile::new().expect("file");
        assert!(
            configured_logger(file.path(), MAX_FILE_BYTES)
                .expect("config")
                .build()
                .is_err()
        );
    }
}
