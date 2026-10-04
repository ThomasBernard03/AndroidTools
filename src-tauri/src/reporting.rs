//! Sentry composition and the authoritative runtime consent gate.

use crate::features::settings::{domain::SettingsError, infrastructure};
use std::{
    path::Path,
    sync::{
        Arc, Mutex,
        atomic::{AtomicBool, Ordering},
    },
};

/// Owns runtime consent and serializes preference updates.
pub struct Reporting {
    enabled: Arc<AtomicBool>,
    settings_lock: Mutex<()>,
}

impl Reporting {
    pub fn new(directory: &Path) -> Self {
        // A corrupt or unreadable preference must never grant consent.
        let enabled = Arc::new(AtomicBool::new(
            infrastructure::load(directory).is_ok_and(|s| s.crash_reporting_enabled),
        ));
        Self {
            enabled,
            settings_lock: Mutex::new(()),
        }
    }

    pub fn options(&self) -> sentry::ClientOptions {
        let gate = self.enabled.clone();
        let mut options = sentry::ClientOptions::default();
        options.dsn = option_env!("SENTRY_DSN").and_then(|value| value.parse().ok());
        options.release = sentry::release_name!();
        options.environment = Some(
            if cfg!(debug_assertions) {
                "development"
            } else {
                "production"
            }
            .into(),
        );
        options.send_default_pii = false;
        options.auto_session_tracking = false;
        options.before_send = Some(Arc::new(move |event| {
            gate.load(Ordering::SeqCst).then_some(event)
        }));
        options
    }

    /// Persist first: failed writes leave the active consent unchanged.
    pub fn save(
        &self,
        directory: &Path,
        enabled: bool,
    ) -> Result<crate::features::settings::domain::AppSettings, SettingsError> {
        let _lock = self
            .settings_lock
            .lock()
            .map_err(|_| SettingsError::storage())?;
        let settings = infrastructure::set_crash_reporting(directory, enabled)?;
        self.enabled
            .store(settings.crash_reporting_enabled, Ordering::SeqCst);
        Ok(settings)
    }

    fn capture(&self, event: &str) {
        if !self.enabled.load(Ordering::SeqCst) || event.len() > 1_048_576 {
            return;
        }
        if let Ok(mut event) = serde_json::from_str::<sentry::protocol::Event<'static>>(event) {
            event.platform = "javascript".into();
            event.release = None;
            event.environment = None;
            sentry::capture_event(event);
        }
    }
}

/// Accepts error events only; sessions, replay and arbitrary envelopes are not forwarded.
#[tauri::command]
pub fn capture_frontend_error(reporting: tauri::State<'_, Reporting>, event: String) {
    reporting.capture(&event);
}

#[cfg(test)]
mod tests {
    use super::*;

    const EVENT: &str = r#"{"exception":{"values":[{"type":"Error","value":"Vue failure"}]}}"#;

    #[test]
    fn consent_controls_native_and_frontend_events_immediately_and_after_restart() {
        let directory = tempfile::tempdir().expect("directory");
        let reporting = Reporting::new(directory.path());
        let events = sentry::test::with_captured_events_options(
            || {
                reporting.capture(EVENT);
                sentry::capture_message("disabled", sentry::Level::Error);
                reporting.save(directory.path(), true).expect("enable");
                reporting.capture(EVENT);
                sentry::capture_message("enabled", sentry::Level::Error);
                assert!(
                    Reporting::new(directory.path())
                        .enabled
                        .load(Ordering::SeqCst)
                );
                reporting.save(directory.path(), false).expect("disable");
                reporting.capture(EVENT);
                sentry::capture_message("disabled again", sentry::Level::Error);
            },
            reporting.options(),
        );
        assert_eq!(events.len(), 2);
        assert_eq!(events[0].platform, "javascript");
        assert_eq!(events[1].message.as_deref(), Some("enabled"));
        assert!(
            !Reporting::new(directory.path())
                .enabled
                .load(Ordering::SeqCst)
        );
    }

    #[test]
    fn failed_save_preserves_consent_and_corrupt_preferences_start_disabled() {
        let directory = tempfile::tempdir().expect("directory");
        let reporting = Reporting::new(directory.path());
        reporting.save(directory.path(), true).expect("enable");
        std::fs::write(directory.path().join("settings.json"), b"broken").expect("corrupt");
        assert!(reporting.save(directory.path(), false).is_err());
        assert!(reporting.enabled.load(Ordering::SeqCst));
        assert!(
            !Reporting::new(directory.path())
                .enabled
                .load(Ordering::SeqCst)
        );
    }

    #[test]
    fn malformed_and_oversized_frontend_events_are_ignored() {
        let directory = tempfile::tempdir().expect("directory");
        let reporting = Reporting::new(directory.path());
        reporting.save(directory.path(), true).expect("enable");
        let events = sentry::test::with_captured_events_options(
            || {
                reporting.capture("broken");
                reporting.capture(&" ".repeat(1_048_577));
            },
            reporting.options(),
        );
        assert!(events.is_empty());
    }
}
